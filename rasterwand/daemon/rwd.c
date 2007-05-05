/*
 * Experimental Linux userspace driver for the Rasterwand
 *
 * The implementation of wand startup is incomplete, and it does
 * not yet support changing parameters at runtime. Reads binary
 * frames over UDP.
 *
 * Copyright (C) 2007 Micah Dowty <micah@navi.cx>
 */

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <time.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <linux/usbdevice_fs.h>
#include <rwand_protocol.h>

#define NUM_OVERLAPPED_URBS 2

#define FILTER_SIZE      256    /* Increasing this will smooth out display jitter
                                 * at the expense of responding more slowly to
                                 * real changes
                                 */
#define PERIOD_TOLERANCE 20     /* Increasing this will reduce the frequency of
                                 * mall jumps in the display alignment at the increased
                                 * risk of having slightly incorrect timing.
                                 */

#define STABILIZER_EDGES   8    /* Number of edges to successfully exit stabilization */
#define STABILIZER_SECONDS 1    /* Time to unsuccessfully exit stabilization */
#define STARTING_EDGES       20

/* A simple averaging low-pass filter, O(1) */
struct filter {
   int buffer[FILTER_SIZE];    /* Circular buffer */
   int total;                  /* Total of all values currently in the buffer */
   int n_values;               /* Number of values currently in the buffer */
   int pointer;                /* Location to store the next new value in */
};

/* Timing calculated from the current status and settings */
struct rwand_timings {
   int    column_width;
   int    gap_width;
   int    fwd_phase;
   int    rev_phase;
   int    coil_begin;
   int    coil_end;
};

struct rwand_settings {
   int display_center;         /* The center of the display. 0 is full left,
                                * 0xFFFF is full right.
                                */
   int display_width;          /* The total width of the display, from 0 (nothing)
                                * to 0xFFFF (the entire wand sweep)
                                */
   int coil_center;            /* The center of the coil pulse. 0 is full left,
                                * 0x4000 is the center on the left-right pass,
                                * 0x8000 is full-right, 0xC000 is center on the
                                * right-left pass, and 0xFFFF is full left again.
                                */
   int coil_width;             /* The width of the coil pulse, from 0 (nothing) to
                                * 0xFFFF (the entire period)
                                */
   int duty_cycle;             /* The ratio of pixels to gaps. 0xFFFF has no gap,
                                * 0x0000 is all gap and no pixel.
                                */
   int fine_adjust;            /* Fine tuning for the front/back alignment */
   int power_mode;             /* RWAND_POWER_* */
   int num_columns;            /* The number of columns actually being displayed.
                                * This is set automatically on write().
                                */
};

struct async_urb;
typedef void (async_urb_callback)(struct async_urb *async);

struct async_urb {
   struct usbdevfs_urb urb;
   async_urb_callback *callback;
   struct {
      struct {
         __u8 bRequestType;
         __u8 bRequest;
         __u16 wValue;
         __u16 wIndex;
         __u16 wLength;
      } setup;
      union {
         __u8 data[16];
         struct {
            __u16 period;
            __u16 phase;
            __u8 edge_count;
            __u8 mode;
            __u8 flip_count;
            __u8 buttons;
         } status;
      };
   };
};

static struct {
   int fd;
   int input_fd;

   enum {
      STATE_OFF,
      STATE_STARTING,
      STATE_STABILIZING,
      STATE_RUNNING,
   } state;

   unsigned int modes;
   unsigned int edge_count;
   int filtered_period;
   int settings_dirty;
   int flip_pending;
   struct timeval stabilizing_deadline;
   struct async_urb last_status_urb;
   struct filter filter;
   struct rwand_settings settings;
} device;


/* Add a new value to the filter, returning the filter's current value */
static int
filter_push(struct filter *filter, int new_value)
{
   if (filter->n_values > FILTER_SIZE) {
      /* Remove the old value if we're full */
      filter->total -= filter->buffer[filter->pointer];
   }
   else {
      filter->n_values++;
   }

   /* Add the new value */
   filter->buffer[filter->pointer] = new_value;
   filter->total += new_value;

   filter->pointer = (filter->pointer + 1) & (FILTER_SIZE-1);
   return filter->total / filter->n_values;
}

static void filter_reset(struct filter *filter)
{
   filter->total = 0;
   filter->n_values = 0;
   filter->pointer = 0;
}

/*
 * Asynchronously submit a URB. Its callback will be invoked later.
 */
void
async_urb_submit(struct async_urb *async)
{
   if (ioctl(device.fd, USBDEVFS_SUBMITURB, async) < 0) {
      perror("USBDEVFS_SUBMITURB");
      exit(1);
   }
}

/*
 * Allocate and zero a new URB
 */
struct async_urb *
async_urb_new()
{
   struct async_urb *async = calloc(1, sizeof *async);
   if (!async) {
      perror("malloc");
      exit(1);
   }
   return async;
}

/*
 * Allocate a new Control URB
 */
struct async_urb *
async_urb_new_control(__u8 bRequestType, __u8 bRequest, __u16 wLength,
                      async_urb_callback *callback)
{
   struct async_urb *async = async_urb_new();

   async->urb.type = USBDEVFS_URB_TYPE_CONTROL;
   async->urb.endpoint = 0;
   async->urb.buffer_length = sizeof async->setup + wLength;
   async->urb.buffer = &async->setup;
   async->setup.bRequestType = bRequestType;
   async->setup.bRequest = bRequest;
   async->setup.wLength = wLength;
   async->callback = callback;

   return async;
}

/*
 * Perform an asynchronous control write, with no completion notification.
 * All asynchronous control writes will be queued and performed in FIFO order.
 */
void
control_write_async(__u8 bRequest, __u16 wValue, __u16 wIndex,
                    __u16 wLength, const char *data)
{
   struct async_urb *urb = async_urb_new_control(0x40, bRequest, wLength,
                                                 (async_urb_callback*) free);
   urb->setup.wValue = wValue;
   urb->setup.wIndex = wIndex;
   memcpy(urb->data, data, wLength);
   async_urb_submit(urb);
}


/* Calculate all the fun little timing parameters needed by the hardware */
static void
rwand_calc_timings(struct rwand_settings *settings, int period,
                   struct rwand_timings *timings)
{
   int col_and_gap_width, total_width;

   /* The coil driver just needs to have its relative timings
    * multiplied by our predictor's current period. This is fixed
    * point math with 16 digits to the right of the binary point.
    */
   timings->coil_begin = (period * (settings->coil_center -
                                    settings->coil_width/2)) >> 16;
   timings->coil_end   = (period * (settings->coil_center +
                                    settings->coil_width/2)) >> 16;

   if (settings->num_columns > 0) {
      /* Now calculate the display timings. We start out with the precise
       * width of our columns, so that the width of the whole display
       * can be calculated accurately.
       */
      col_and_gap_width = (period / settings->num_columns *
                           settings->display_width) >> 17;
      timings->column_width = (col_and_gap_width * settings->duty_cycle) >> 16;
      timings->gap_width = col_and_gap_width - timings->column_width;
      total_width =
         (settings->num_columns) * timings->column_width +
         (settings->num_columns-1) * timings->gap_width;


      /* Now that we know the true width of the display, we can calculate the
       * two phase timings. These indicate when it starts the forward scan and the
       * backward scan, relative to the left position. The alignment between
       * the forward and backward scans should be calculated correctly, but it
       * can be tweaked using settings->fine_adjust. This value is set per-model
       * to account for latency in the interruption sensor and LED drive hardware.
       */
      timings->fwd_phase = ((period * settings->display_center) >> 17) - total_width/2;
      timings->rev_phase = period - timings->fwd_phase -
         total_width + settings->fine_adjust;
   }
   else {
      /* We can't calculate timings for a zero-width display without dividing by
       * zero, so just fill in some invalid timings that will blank the display.
       */
      timings->column_width = 1;
      timings->gap_width = 1;
      timings->fwd_phase = 0xFFFF;
      timings->rev_phase = 0xFFFF;
   }
}

/*
 * Change the device's mode. If the mode is actually different from the
 * current mode, this queues a control request.
 */
void
device_set_modes(int modes)
{
   if (modes != device.modes) {
      device.modes = modes;
      control_write_async(RWAND_CTRL_SET_MODES, modes, 0, 0, NULL);
   }
}

/*
 * Asynchronously write a frame to the device.
 * Frame width should be a multiple of 4.
 */
void
write_frame(unsigned char *data, int width)
{
   if (width != device.settings.num_columns) {
      device.settings.num_columns = width;
      device.settings_dirty = 1;
   }

   while (width > 0) {
      control_write_async(RWAND_CTRL_SEQ_WRITE4,
                          data[0] | (data[1] << 8),
                          data[2] | (data[3] << 8),
                          0, NULL);
      width -= 4;
      data += 4;
   }

   control_write_async(RWAND_CTRL_FLIP, 0, 0, 0, NULL);
   device.flip_pending = 1;
}


/*
 * Completion callback for status URBs. This drives the main control
 * loop for the device. We always re-submit the status URB, in order
 * to keep the loop going.
 */
void
status_urb_complete(struct async_urb *async)
{
   device.edge_count += async->status.edge_count -
      device.last_status_urb.status.edge_count;

   if (async->status.flip_count != device.last_status_urb.status.flip_count) {
      device.flip_pending = 0;
   }

   if (async->status.buttons & RWAND_BUTTON_POWER) {
      if (device.state == STATE_OFF) {
         device.state = STATE_STARTING;
         device.edge_count = 0;
      }
   } else {
      device.state = STATE_OFF;
   }

   switch (device.state) {

   case STATE_OFF: {
      device_set_modes(0);
      break;
   }

   case STATE_STARTING: {
      device_set_modes(RWAND_MODE_ENABLE_COIL);

      /* XXX: Not setting coil parameters yet */

      if (device.edge_count > STARTING_EDGES) {
         device.edge_count = 0;
         gettimeofday(&device.stabilizing_deadline, NULL);
         device.stabilizing_deadline.tv_sec += STABILIZER_SECONDS;
         device.state = STATE_STABILIZING;
      }
      break;
   }

   case STATE_STABILIZING: {
      struct timeval now = {0};

      if (device.edge_count > STABILIZER_EDGES) {
         /* Success */
         device.state = STATE_RUNNING;
         filter_reset(&device.filter);
         device.filtered_period = 0;
         break;
      }

      gettimeofday(&now, NULL);
      if (device.stabilizing_deadline.tv_sec < now.tv_sec ||
          (device.stabilizing_deadline.tv_sec == now.tv_sec &&
           device.stabilizing_deadline.tv_usec < now.tv_usec)) {
         /* Timed out */
         device.state = STATE_STARTING;
      }
      break;
   }

   case STATE_RUNNING: {
      int new_filtered_period;
      int width;
      unsigned char frame_buffer[80];

      device_set_modes(RWAND_MODE_ENABLE_COIL |
                       RWAND_MODE_STALL_DETECT |
                       RWAND_MODE_ENABLE_SYNC |
                       RWAND_MODE_ENABLE_DISPLAY);

      /*
       * If the display just turned off, the firmware
       * detected a stall. Go to STATE_STARTING.
       */
      if ((device.last_status_urb.status.mode & RWAND_MODE_ENABLE_DISPLAY) &&
          !(async->status.mode & RWAND_MODE_ENABLE_DISPLAY)) {
         device.state = STATE_STARTING;
         device.edge_count = 0;
         break;
      }

      if (!device.flip_pending) {
         /* See if we can read a new frame */
         width = read(device.input_fd, frame_buffer, sizeof frame_buffer);
         if (width >= 0) {
            write_frame(frame_buffer, width);
         }
      }

      new_filtered_period = filter_push(&device.filter, async->status.period);

      if (device.settings_dirty ||
          abs(new_filtered_period - device.filtered_period) > PERIOD_TOLERANCE) {

         struct rwand_timings timings;
         device.settings_dirty = 0;

         rwand_calc_timings(&device.settings, new_filtered_period, &timings);
         device.filtered_period = new_filtered_period;

         control_write_async(RWAND_CTRL_SET_COIL_PHASE,
                             timings.coil_begin, timings.coil_end, 0, NULL);
         control_write_async(RWAND_CTRL_SET_COLUMN_WIDTH,
                             timings.column_width, timings.gap_width, 0, NULL);
         control_write_async(RWAND_CTRL_SET_DISPLAY_PHASE,
                             timings.fwd_phase, timings.rev_phase, 0, NULL);
         control_write_async(RWAND_CTRL_SET_NUM_COLUMNS,
                             device.settings.num_columns, 0, 0, NULL);
      }

      break;
   }
   }

   device.last_status_urb = *async;
   async_urb_submit(async);
}


/*
 * Initialize the device by resetting its mode and submitting all
 * initial status requests.
 */
void
device_init()
{
   int i;

   device.settings.display_center = 0x8000;
   device.settings.display_width  = 0x7C00;
   device.settings.coil_center    = 0x4000;
   device.settings.coil_width     = 0x7000;
   device.settings.duty_cycle     = 0xA000;
   device.settings.fine_adjust    = -185;
   device.settings.num_columns    = 80;

   control_write_async(RWAND_CTRL_SET_MODES, 0, 0, 0, NULL);

   for (i=0; i<NUM_OVERLAPPED_URBS; i++) {
      async_urb_submit(async_urb_new_control(0xc0, RWAND_CTRL_READ_STATUS, 8,
                                             status_urb_complete));
   }
}

/*
 * Open the device, initialize it, then run the main loop. This waits
 * for completed URBs and invokes the proper callbacks.
 */
int
main(int argc, char **argv)
{
   struct sockaddr_in listen_addr;

   if (argc != 3) {
      fprintf(stderr, "usage: %s /proc/bus/usb/<BUS>/<ADDR> <UDP port>\n", argv[0]);
      return 1;
   }

   /*
    * Open the USB device
    */
   device.fd = open(argv[1], O_RDWR);
   if (device.fd < 0) {
      perror("open");
      return 1;
   }

   /*
    * Open a nonblocking UDP socket
    */
   memset(&listen_addr, 0, sizeof listen_addr);
   listen_addr.sin_family = AF_INET;
   listen_addr.sin_port = htons(atoi(argv[2]));

   device.input_fd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
   if (device.input_fd < 0) {
      perror("socket");
      return 1;
   }

   if (bind(device.input_fd, (void*) &listen_addr, sizeof listen_addr) < 0) {
      perror("bind");
      return 1;
   }
   if (fcntl(device.input_fd, F_SETFL,
             fcntl(device.input_fd, F_GETFL) | O_NONBLOCK) < 0) {
      perror("fcntl");
      return 1;
   }

   device_init();

   while (1) {
      struct async_urb *async = NULL;
      if (ioctl(device.fd, USBDEVFS_REAPURB, &async) < 0) {
         perror("USBDEVFS_REAPURB");
      }
      if (async) {
         async->callback(async);
      }
   }
}