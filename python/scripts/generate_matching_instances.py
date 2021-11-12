#!/usr/bin/env python3

from anytree import Node, RenderTree
from anytree.util import commonancestors
import sys
import random

#########################
#
# AUXILIARY FUNCTIONS
#
#########################


# generate a weighted graph
def generate_graph(num_nodes, num_odd_sets, size_odd_sets, identifier, weighted):

    nodes = list(range(num_nodes))
    edges = []
    objective = []

    random.seed(identifier)
    for t in range(num_odd_sets):
        subset = random.sample(nodes, size_odd_sets)
        for e in [(i, j) for i in subset for j in subset if i < j]:
            if e not in edges:
                edges.append(e)
                objective.append(1)

    radix = 3 # 2 makes binary tree, 3 makes trinary tree

    # odd radix means only odd sets
    sets = []
    dict = {}
    cnt = 0
    for i in nodes:
        dict[i] = Node(i, size=1)
        sets.append(dict[i])

    while len(sets) >= radix:
        node = Node('i', ident = cnt)
        cnt += 1
        siz = 0
        for c in range(radix):
            idx = random.randint(0,len(sets)-1)
            sets[idx].parent = node
            siz = siz + sets[idx].size
            del sets[idx]
        node.size = siz
        sets.append(node)

    if weighted == 1:
        for i in range(len(edges)):
            # if e is in S, add to e's weight 2/(|S| - 1)
            weight = 0
            for an in commonancestors(dict[edges[i][0]],dict[edges[i][1]]):
                weight = weight + 2./(an.size - 1)
            objective[i] = weight

    return nodes, edges, objective

# write graph to file
def write_graph(nodes, edges, objective, basename, identifier):

    f = open(basename+"%d.col" % identifier, 'w')

    f.write("p edge %d %d\n" % (len(nodes), len(edges)))
    for i in range(len(edges)):
        u = edges[i][0] + 1
        v = edges[i][1] + 1
        obj = objective[i]
        f.write("e %d %d %f\n" % (u, v, obj))

    f.close()


#########################
#
# MAIN PART
#
#########################
            
num_nodes = int(sys.argv[1])
num_odd_sets = int(sys.argv[2])
size_odd_sets = int(sys.argv[3])
basename = sys.argv[4]
identifier = int(sys.argv[5])
weighted = int(sys.argv[6])

nodes, edges, objective = generate_graph(num_nodes, num_odd_sets, size_odd_sets, identifier, weighted)

write_graph(nodes, edges, objective, basename, identifier)

