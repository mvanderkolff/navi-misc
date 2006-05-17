#!/usr/bin/env python
#
# interpolate.py
#
# Copyright (C) 2005-2006 W. Evan Sheehan
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#

"""Interpolate between two frames in an AMC file.

usage: interpolate.py <asf file> <graph> <bayes net> <input amc> <output amc> <start frame> <end frame>
"""

from Motion import AMC, ASFReader
from Dance import MotionGraph
from Graph import algorithms_c
from Graph.Data import VertexMap, AdjacencyList, CNode
from Graph.ExtraAlgorithms import ParallelBFS, Heuristic
import Numeric, sys, pickle

# completely arbitrary
EPSILON = 0.3**15

def comb(bones, items, position=0, current=[], current_probability=1.0):
    """Return a list of successors for a node. Prune out successors with a low
       probability. Yay Bayes net!
       """
    results = []
    bone = bones[position]

    def find(list, item):
        for i in range(len(list)):
            if list[i] == item:
                return i
        return -1

    net = bayes_net[bone]
    if bone in parents:
        parent = parents[bone]

        parent_pos = find(bones, parent)
        pbone = current[parent_pos]

    for item in items[position]:
        if not (bone in parents and \
                (asf.bones[bone].dof or \
                 (parent in asf.bones and \
                  asf.bones[parent].dof))) or \
           parent_pos == -1:
            # We're either on the root or a bone whose parent has no DOF.
            # The bayes net has entries for these, just they're histograms
            # of the bone's position, and so the probabilities are kind of
            # low.  Treat them as if they all pass
            new_current = current + [item]
            if position == len(bones) - 1:
                results.append(new_current)
            else:
                children = comb(bones, items, position + 1, new_current, current_probability)
                if len(children):
                    results.extend(children)
                pass
        else:
            spot = (tuple(pbone.mins), tuple(item.mins))
            if spot in net:
                probability = net[spot]
                new_current = current + [item]
                new_prob = current_probability * probability
                if new_prob > EPSILON and probability > 0.1:
                    if position == len(bones) - 1:
                        results.append(new_current)
                    else:
                        children = comb(bones, items, position + 1, new_current, new_prob)
                        if len(children):
                            results.extend(children)

    res = len(results)
    if position == 0:
        print '%d likely successors' % res
    return results

def successor (graphs, node):
    """Generate successors of a combinatoric node."""
    immediate_successors = {}
    # Create a dictionary mapping bone name to the list of successors for that
    # bone in its current position.
    for bone, n in node.iteritems ():
        adj = graphs[bone].representations[AdjacencyList]
        immediate_successors[bone] = [edge.v for edge in adj.query (n)]

    # Return a list of the combinatoric nodes
    items = []
    bones = []
    for bone in comb_order:
        if bone in immediate_successors:
            bones.append(bone)
            items.append(immediate_successors[bone])

    retval = []
    for succ in comb(bones, items):
        retsucc = {}
        for pos in range(len(succ)):
            retsucc[bones[pos]] = succ[pos]
        retval.append(CNode(retsucc))
    return retval

def find_node (graph, pos):
    vertex_map = graph.representations[VertexMap]
    for vertex in vertex_map:
        if vertex.inside (pos):
            return vertex

def fixnegative (x):
    while x < 0:
        x = x + 360
    return x

def fix360 (x):
    if x == 360:
        return 0
    return x

def linear_interp(start, end, pos, length):
    result = []
    for i in range(len(start)):
        compstart = start[i]
        compend   = end[i]

        pos = compstart + ((compend - compstart) * (float(pos) / float(length)))
        result.append(pos)
    return result

def f (path, goal):
    end = path[-1]
    g = len (path)
    h = 0

    for bone in end.iterkeys():
        adj = adjacency[bone]
        endb = end.get(bone)
        goalb = goal.get(bone)

        if bone not in cached_costs:
            cached_costs[bone] = {}
        if (endb, goalb) in cached_costs[bone]:
            h += cached_costs[bone][(endb, goalb)]
            continue

        path = algorithms_c.dijkstraSearch(adj, endb, goalb)
        h += len(path)

        for i in range(1, len(path)):
            x = path[i]
            cached_costs[bone][(endb, x)] = i + 1

        for i in range(0, len(path) - 1):
            x = path[i]
            cached_costs[bone][(x, goalb)] = i + 2

    return (g + h)

def build_order(asf):
    order = ['root']
    pos = 0
    while pos < len(order):
        for group in asf.hierarchy:
            if len(group) and group[0] == order[pos]:
                order.extend(group[1:])
        pos += 1

    return order


if len(sys.argv) < 8:
    print "usage: %s <asf file> <graph> <bayes net> <input amc> <output amc> <start frame> <end frame>" % (sys.argv[0])
    sys.exit(1)

samc = AMC.from_file(sys.argv[4])

print 'loading asf'
asf = ASFReader()
asf.parse(sys.argv[1])

# Get the build order
comb_order = build_order(asf)
parents = {}
for group in asf.hierarchy:
    if len(group) == 0:
        continue
    for child in group[1:]:
        parents[child] = group[0]

print 'loading graphs'
graphs = pickle.load(open(sys.argv[2]))

print 'loading bayes net'
bayes_net = pickle.load(open(sys.argv[3]))

# Need the adjacency lists in the f-cost function
adjacency = {}
for bone, graph in graphs.iteritems():
    adjacency[bone] = graph.representations[AdjacencyList]

cached_costs = {}

starts = {}
ends = {}

# Build the dictionaries for the starting and ending nodes to interpolate
for bone in samc.bones.keys ():
    start = samc.bones[bone][int(sys.argv[-2])]
    end   = samc.bones[bone][int(sys.argv[-1])]

    if bone == 'root':
        start = start[3:6]
        end   = end[3:6]

    start = [Numeric.remainder (d, 360.0) for d in start]
    end   = [Numeric.remainder (d, 360.0) for d in end]

    start = tuple (map (fix360, map (fixnegative, start)))
    end   = tuple (map (fix360, map (fixnegative, end)))

    startNode = find_node (graphs[bone], start)
    endNode   = find_node (graphs[bone], end)

    starts[bone] = startNode
    ends[bone] = endNode

paths = Heuristic (graphs, CNode (starts), CNode (ends), f, successor).run ()
print paths

if paths is None:
    print 'no path found!'
    sys.exit ()

# for i in range(len(paths)):
    # frame = {}
    # for bone in paths[i].data.keys():
        # node = paths[i].data[bone]
        # center = node.center

        # if bone == 'root':
            # Linearly interpolate root position, for now
            # rootstart = pre[1].bones['root'][0:3]
            # rootend   = post[1].bones['root'][0:3]
            # position = linear_interp (rootstart, rootend, i, len(paths))
            # center = position + center
        # frame[bone] = center
    # sequence.insert (frame, boundary + i)

# sequence.save(args[5], samc.format)

# vim: ts=4:sw=4:et