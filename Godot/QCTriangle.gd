class_name QCTriangle

var qc : QC
var sideO : bool
var sideL : bool
var edges : Array

func _init(pQC:QC, pSideO:bool, pSideL:bool):
	qc = pQC
	sideO = pSideO
	sideL = pSideL
	if sideO: edges = [qc.edges[0], qc.edges[1], qc.edges[2]] if sideL else [qc.edges[0], qc.edges[1], qc.edges[3]]
	else: edges = [qc.edges[2], qc.edges[3], qc.edges[0]] if sideL else [qc.edges[2], qc.edges[3], qc.edges[1]]


func getNeighbors() -> Array:
	return [
		qc.triangle2 if qc.triangle1 == self else qc.triangle1,
		qc.get_horizontalTriangleNeighbor(sideL),
		qc.get_verticalTriangleNeighbor(sideO)	
		]
