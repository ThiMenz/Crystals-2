class_name MapTriangle extends Node

var edges = []
var neighbors = []
var debugDiagonal : bool

func _init(pEdges, pDebugDiagonal : bool):
	edges = pEdges
	debugDiagonal = pDebugDiagonal

func checkForNeighborTriangle(pTriangle: MapTriangle):
	var tc:int = 0
	for i in range(3):
		var v = pTriangle.edges[i]
		for j in range(3):
			if v == edges[j]:
				tc += 1
				break
				
	if tc == 2:
		pTriangle.neighbors.append(self)
		neighbors.append(pTriangle)
