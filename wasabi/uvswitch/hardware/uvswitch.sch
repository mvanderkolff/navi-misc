v 20030525
C 29450 68950 1 0 0 usbheader.sym
{
T 29450 70350 5 10 1 1 0 0
refdes=J1
T 29550 68750 5 10 1 1 0 0
value=USB
}
N 31150 69450 31850 69450 4
N 31850 69450 31850 73950 4
N 31850 73950 31150 73950 4
N 31150 69750 31550 69750 4
N 31550 69750 31550 73550 4
N 31550 73550 31150 73550 4
C 32150 70250 1 0 0 5V-plus-1.sym
C 32250 68550 1 0 0 gnd-1.sym
N 31150 69150 32350 69150 4
N 32350 69150 32350 68850 4
N 31150 70050 32350 70050 4
N 32350 70050 32350 70250 4
C 26650 70250 1 90 0 capacitor-1.sym
{
T 26150 70850 5 10 1 1 180 0
refdes=C3
T 26150 70650 5 10 1 1 180 0
value=0.22uf
}
C 26350 69850 1 0 0 gnd-1.sym
N 26450 70150 26450 70250 4
N 26450 71150 26450 73550 4
N 26450 73550 26950 73550 4
C 28650 71350 1 0 0 resistor-1.sym
{
T 28850 71650 5 10 1 1 0 0
refdes=R1
T 28850 71150 5 10 1 1 0 0
value=1.5k
}
N 28650 71450 26450 71450 4
N 29550 71450 31550 71450 4
C 31550 77150 1 0 0 5V-plus-1.sym
C 26550 80650 1 90 0 resistor-1.sym
{
T 26250 80850 5 10 1 1 90 0
refdes=R2
T 26550 80650 5 10 1 1 0 0
value=10k
}
N 26450 80650 26450 80350 4
N 26450 80350 26950 80350 4
C 26250 81750 1 0 0 5V-plus-1.sym
N 26450 81750 26450 81550 4
C 32150 70050 1 270 0 capacitor-2.sym
{
T 32650 69650 5 10 1 1 0 0
refdes=C4
T 32650 69450 5 10 1 1 0 0
value=10uf
}
C 32050 76950 1 0 0 capacitor-1.sym
{
T 32350 77050 5 10 1 1 180 0
refdes=C5
T 32950 77050 5 10 1 1 180 0
value=0.1uf
}
N 31150 76750 33350 76750 4
T 46100 65600 9 20 1 0 0 0
USB Video Switch
T 45900 65100 9 10 1 0 0 0
uvswitch.sch
T 46950 64800 9 10 1 0 0 0
1
T 47400 64800 9 10 1 0 0 0
1
T 50000 65100 9 10 1 0 0 0
$Rev$
T 50000 64800 9 10 1 0 0 0
Micah Dowty
N 31150 77150 32050 77150 4
N 32950 77150 33350 77150 4
N 33350 76450 33350 77150 4
C 26850 72250 1 0 0 pic16c765.sym
{
T 30650 80850 5 10 1 1 0 0
refdes=U1
}
C 23750 76550 1 0 0 5V-plus-1.sym
N 23950 76550 23950 76350 4
N 26950 75950 22450 75950 4
C 22700 76150 1 0 0 capacitor-1.sym
{
T 23500 76250 5 10 1 1 180 0
refdes=C9
T 23300 76450 5 10 1 1 0 0
value=0.1uf
}
N 23600 76350 26950 76350 4
N 22700 76350 22450 76350 4
N 22850 74750 22850 75550 4
C 23800 75650 1 180 0 crystal-1.sym
{
T 23500 75850 5 10 1 1 180 0
refdes=X1
T 23100 75250 5 10 1 1 0 0
value=6 MHz
}
N 23800 75550 26950 75550 4
N 26950 75150 22850 75150 4
N 22850 75550 23100 75550 4
C 23050 73850 1 90 0 capacitor-1.sym
{
T 23200 74150 5 10 1 1 180 0
refdes=C11
T 22950 73850 5 10 1 1 0 0
value=20pf
}
C 24250 73850 1 90 0 capacitor-1.sym
{
T 24450 74150 5 10 1 1 180 0
refdes=C12
T 24150 73850 5 10 1 1 0 0
value=20pf
}
N 24050 74750 24050 75550 4
C 22750 73350 1 0 0 gnd-1.sym
C 23950 73350 1 0 0 gnd-1.sym
N 24050 73850 24050 73650 4
N 22850 73850 22850 73650 4
N 22450 76350 22450 75650 4
C 22350 75350 1 0 0 gnd-1.sym
C 47050 78950 1 0 0 max4572.sym
{
T 47450 85850 5 10 1 1 0 0
refdes=U2
}
C 48350 86050 1 0 0 5V-plus-1.sym
C 33250 76150 1 0 0 gnd-1.sym
C 48050 78650 1 0 0 gnd-1.sym
N 48150 78950 48150 79050 4
N 48550 86050 48550 85850 4
C 47050 70900 1 0 0 max4572.sym
{
T 47450 77800 5 10 1 1 0 0
refdes=U3
}
C 48350 78000 1 0 0 5V-plus-1.sym
C 48050 70600 1 0 0 gnd-1.sym
N 48150 70900 48150 71000 4
N 48550 78000 48550 77800 4
N 49500 83150 49500 84950 4
N 49500 84350 49150 84350 4
N 49500 83750 49150 83750 4
N 49500 83150 49150 83150 4
N 49500 81950 49150 81950 4
N 49500 81350 49150 81350 4
N 49150 82550 50050 82550 4
N 49500 76900 49500 82550 4
N 49150 82250 49500 82250 4
N 49150 76900 49500 76900 4
N 49150 76300 50050 76300 4
N 49500 75700 49150 75700 4
N 49500 75100 49150 75100 4
N 49500 73900 49500 76300 4
N 49500 73900 49150 73900 4
C 50550 84450 1 0 1 BNC-1.sym
{
T 50250 85200 5 10 1 1 0 0
refdes=VID_OUT
}
C 50550 84100 1 0 1 gnd-1.sym
N 50450 84400 50450 84450 4
N 49150 84950 50050 84950 4
C 50550 82050 1 0 1 BNC-1.sym
{
T 50250 82800 5 10 1 1 0 0
refdes=AUD_LEFT_OUT
}
C 50550 81700 1 0 1 gnd-1.sym
N 50450 82000 50450 82050 4
C 50550 75800 1 0 1 BNC-1.sym
{
T 50250 76550 5 10 1 1 0 0
refdes=AUD_RIGHT_OUT
}
C 50550 75450 1 0 1 gnd-1.sym
N 50450 75750 50450 75800 4
C 42000 80250 1 0 0 connector8-1.sym
{
T 42000 80050 5 10 1 1 0 0
refdes=AUD_LEFT_IN
}
C 42000 74000 1 0 0 connector8-1.sym
{
T 42050 73800 5 10 1 1 0 0
refdes=AUD_RIGHT_IN
}
C 36350 82650 1 0 0 connector8-1.sym
{
T 36400 82450 5 10 1 1 0 0
refdes=VID_IN
}
N 43700 76300 47150 76300 4
N 43700 76000 47150 76000 4
N 43700 75700 47150 75700 4
N 43700 75400 47150 75400 4
N 43700 75100 47150 75100 4
N 43700 74800 47150 74800 4
N 43850 74200 43850 73600 4
N 43850 73600 47150 73600 4
N 43700 74500 44100 74500 4
N 44100 74500 44100 73900 4
N 44100 73900 47150 73900 4
N 43700 82550 47150 82550 4
N 43700 82250 47150 82250 4
N 43700 81950 47150 81950 4
N 43700 81650 47150 81650 4
N 43700 81350 47150 81350 4
N 43700 81050 47150 81050 4
N 43850 80450 43850 76600 4
N 43850 76600 47150 76600 4
N 43700 80750 44100 80750 4
N 44100 80750 44100 76900 4
N 44100 76900 47150 76900 4
N 43850 80450 43700 80450 4
N 43850 74200 43700 74200 4
N 38050 84950 47150 84950 4
N 38050 84650 47150 84650 4
N 38050 84350 47150 84350 4
N 38050 84050 47150 84050 4
N 38050 83750 47150 83750 4
N 38050 83450 47150 83450 4
N 38050 83150 47150 83150 4
N 38050 82850 47150 82850 4
C 41050 76250 1 90 0 resistor-1.sym
C 40750 76250 1 90 0 resistor-1.sym
C 40450 76250 1 90 0 resistor-1.sym
C 40150 76250 1 90 0 resistor-1.sym
C 39850 76250 1 90 0 resistor-1.sym
C 39550 76250 1 90 0 resistor-1.sym
C 39250 76250 1 90 0 resistor-1.sym
C 38950 76250 1 90 0 resistor-1.sym
T 37950 76650 9 10 1 0 0 0
8x 100k
C 41050 81450 1 90 0 resistor-1.sym
C 40750 81450 1 90 0 resistor-1.sym
C 40450 81450 1 90 0 resistor-1.sym
C 40150 81450 1 90 0 resistor-1.sym
C 39850 81450 1 90 0 resistor-1.sym
C 39550 81450 1 90 0 resistor-1.sym
C 39250 81450 1 90 0 resistor-1.sym
C 38950 81450 1 90 0 resistor-1.sym
T 38200 81800 9 10 1 0 0 0
8x 1k
N 40950 81450 40950 77150 4
N 40650 81450 40650 77150 4
N 40350 81450 40350 77150 4
N 40050 81450 40050 77150 4
N 39750 81450 39750 77150 4
N 39450 81450 39450 77150 4
N 39150 81450 39150 77150 4
N 38850 81450 38850 77150 4
N 40950 76250 40950 75950 4
N 40650 76250 40650 75950 4
N 40350 76250 40350 75950 4
N 40050 76250 40050 75950 4
N 39750 76250 39750 75950 4
N 39450 76250 39450 75950 4
N 39150 76250 39150 75950 4
N 38850 75700 38850 76250 4
N 38850 75950 40950 75950 4
C 38750 75400 1 0 0 gnd-1.sym
N 40950 82850 40950 82350 4
N 40650 83150 40650 82350 4
N 40350 83450 40350 82350 4
N 40050 83750 40050 82350 4
N 39750 84050 39750 82350 4
N 39450 84350 39450 82350 4
N 39150 84650 39150 82350 4
N 38850 84950 38850 82350 4
U 37750 77350 37750 80900 10 -1
U 37750 80900 37250 80900 10 0
C 37250 80700 1 0 1 interpage_to-1.sym
{
T 36050 80850 5 10 1 1 0 6
pages=VID_DETECT
}
N 38850 80600 37950 80600 4
C 37950 80600 1 180 0 busripper-1.sym
N 39150 80200 37950 80200 4
C 37950 80200 1 180 0 busripper-1.sym
N 39450 79800 37950 79800 4
C 37950 79800 1 180 0 busripper-1.sym
N 39750 79400 37950 79400 4
C 37950 79400 1 180 0 busripper-1.sym
N 40050 79000 37950 79000 4
C 37950 79000 1 180 0 busripper-1.sym
N 40350 78600 37950 78600 4
C 37950 78600 1 180 0 busripper-1.sym
N 40650 78200 37950 78200 4
C 37950 78200 1 180 0 busripper-1.sym
N 40950 77800 37950 77800 4
C 37950 77800 1 180 0 busripper-1.sym
C 46750 78900 1 0 0 gnd-1.sym
N 46850 79200 46850 80550 4
N 46850 80550 47150 80550 4
N 47150 80250 46850 80250 4
C 46750 70850 1 0 0 gnd-1.sym
N 46850 71150 46850 72200 4
N 46850 72200 47150 72200 4
C 46650 72700 1 0 0 5V-plus-1.sym
N 47150 72500 46850 72500 4
N 46850 72500 46850 72700 4
C 20000 64500 1 0 0 title-bordered-A1.sym
C 46550 71700 1 0 1 small_interpage_bidir.sym
{
T 45150 71850 5 10 1 1 0 6
pages=SCL
}
C 46550 71400 1 0 1 small_interpage_bidir.sym
{
T 45150 71550 5 10 1 1 0 6
pages=SDA
}
N 46550 71900 47150 71900 4
N 47150 71600 46550 71600 4
C 46550 79750 1 0 1 small_interpage_bidir.sym
{
T 45150 79900 5 10 1 1 0 6
pages=SCL
}
N 46550 79950 47150 79950 4
N 47150 79650 46550 79650 4
C 46550 79450 1 0 1 small_interpage_bidir.sym
{
T 45150 79600 5 10 1 1 0 6
pages=SDA
}
U 24800 80250 24300 80250 10 0
N 26950 79950 25000 79950 4
C 25000 79950 1 180 0 busripper-1.sym
N 26950 79550 25000 79550 4
C 25000 79550 1 180 0 busripper-1.sym
N 26950 79150 25000 79150 4
C 25000 79150 1 180 0 busripper-1.sym
N 26950 78750 25000 78750 4
C 25000 78750 1 180 0 busripper-1.sym
N 26600 78350 25000 78350 4
C 25000 78350 1 180 0 busripper-1.sym
N 26400 77950 25000 77950 4
C 25000 77950 1 180 0 busripper-1.sym
N 26200 77550 25000 77550 4
C 25000 77550 1 180 0 busripper-1.sym
N 26000 77150 25000 77150 4
C 25000 77150 1 180 0 busripper-1.sym
U 24800 76800 24800 80250 10 -1
C 24300 80050 1 0 1 interpage_from-1.sym
{
T 23100 80200 5 10 1 1 0 6
pages=VID_DETECT
}
T 38050 80650 9 10 1 0 0 0
0
T 38050 80250 9 10 1 0 0 0
1
T 38050 79850 9 10 1 0 0 0
2
T 38050 79450 9 10 1 0 0 0
3
T 38050 79050 9 10 1 0 0 0
4
T 38050 78650 9 10 1 0 0 0
5
T 38050 78250 9 10 1 0 0 0
6
T 38050 77850 9 10 1 0 0 0
7
T 25050 80000 9 10 1 0 0 0
0
T 25050 79600 9 10 1 0 0 0
1
T 25050 79200 9 10 1 0 0 0
2
T 25050 78800 9 10 1 0 0 0
3
T 25050 78400 9 10 1 0 0 0
4
T 25050 78000 9 10 1 0 0 0
5
T 25050 77600 9 10 1 0 0 0
6
T 25050 77200 9 10 1 0 0 0
7
N 26000 77150 26000 76750 4
N 26000 76750 26950 76750 4
N 26200 77550 26200 77150 4
N 26200 77150 26950 77150 4
N 26400 77950 26400 77550 4
N 26400 77550 26950 77550 4
N 26600 78350 26600 77950 4
N 26600 77950 26950 77950 4
C 35300 74150 1 0 0 small_interpage_bidir.sym
{
T 36700 74300 5 10 1 1 0 0
pages=SCL
}
C 35300 74550 1 0 0 small_interpage_bidir.sym
{
T 36700 74700 5 10 1 1 0 0
pages=SDA
}
N 35300 74350 31150 74350 4
N 31150 74750 35300 74750 4
C 34400 75050 1 90 0 resistor-1.sym
{
T 34650 75750 5 10 1 1 180 0
refdes=R2
T 34450 75400 5 10 1 1 0 0
value=4.7k
}
C 35100 75050 1 90 0 resistor-1.sym
{
T 35350 75750 5 10 1 1 180 0
refdes=R3
T 35150 75400 5 10 1 1 0 0
value=4.7k
}
C 34100 76150 1 0 0 5V-plus-1.sym
N 34300 76150 34300 75950 4
C 34800 76150 1 0 0 5V-plus-1.sym
N 35000 76150 35000 75950 4
N 35000 75050 35000 74350 4
N 34300 75050 34300 74750 4
C 25300 70400 1 90 0 led-3.sym
{
T 24700 70900 5 10 1 1 180 0
refdes=D14
}
C 25000 69850 1 0 0 gnd-1.sym
C 25200 71550 1 90 0 resistor-1.sym
{
T 25450 72250 5 10 1 1 180 0
refdes=R4
T 25250 71900 5 10 1 1 0 0
value=270
}
N 25100 71550 25100 71300 4
N 25100 70400 25100 70150 4
N 25100 72450 25100 73950 4
N 25100 73950 26950 73950 4
C 49800 77700 1 0 0 capacitor-1.sym
{
T 50100 77800 5 10 1 1 180 0
refdes=C12
T 50700 77800 5 10 1 1 180 0
value=0.1uf
}
C 51000 77400 1 0 1 gnd-1.sym
N 50700 77900 50900 77900 4
N 50900 77900 50900 77700 4
N 49800 77900 48550 77900 4
C 49050 85750 1 0 0 capacitor-1.sym
{
T 49350 85850 5 10 1 1 180 0
refdes=C13
T 49950 85850 5 10 1 1 180 0
value=0.1uf
}
C 50250 85450 1 0 1 gnd-1.sym
N 49950 85950 50150 85950 4
N 50150 85950 50150 85750 4
N 49050 85950 48550 85950 4
