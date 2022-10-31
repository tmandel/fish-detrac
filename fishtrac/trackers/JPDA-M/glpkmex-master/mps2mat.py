# Copyright (C) 2011 Tommaso Balercia.
#
#This file is part of GLPKMEX.
#
#GLPKMEX is free software; you can redistribute it and/or modify it
#under the terms of the GNU General Public License as published by the
#Free Software Foundation; either version 2, or (at your option) any
#later version.
#
#GLPKMEX is distributed in the hope that it will be useful, but WITHOUT
#ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#for more details.
#
#You should have received a copy of the GNU General Public License
#along with Octave; see the file COPYING.  If not, write to the Free
#Software Foundation, 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

import glpk
import sys
import numpy
import scipy.io as scio

if len(sys.argv) != 2:
	print "Usage: python " + sys.argv[0] + " <MPS file>"
else:

	lp = glpk.LPX(freemps=sys.argv[1])
	obj = list(lp.obj)

	vartype = []
	lbound = []
	ubound = []

	cols = len(lp.cols)
	rows = len(lp.rows)

	for i in range(0,cols):
		if lp.cols[i].kind == float:
			vartype.append('C');
			(lb,ub) = lp.cols[i].bounds
			if lb == None:
				lbound.append(float("Inf"))
			else:
				lbound.append(lb)
			if ub == None:
				ubound.append(float("Inf"))
			else:
				ubound.append(ub)
	
		if lp.cols[i].kind == int:
			vartype.append('I');
			(lb,ub) = lp.cols[i].bounds
			if lb == None:
				lbound.append(0) # This complies with how GLPK would normally work
			else:
				lbound.append(lb)
			if ub == None:
				ubound.append(1) # This complies with how GLPK would normally work
			else:
				ubound.append(ub)
		
	
		if lp.cols[i].kind == bool:
			vartype.append('B');
			lbound.append(0)
			ubound.append(1)
	
	bndtype = []
	bounds = []
	
	for i in range(1,rows):
	
		(lb,ub) = lp.rows[i].bounds
	
		if lb == None and ub == None:
			bndtype.append('F')
			bounds.append(0)
		if lb == None and ub != None:
			bndtype.append('U')
			bounds.append(ub)
		if lb != None and ub == None:
			bndtype.append('L')
			bounds.append(lb)
		if lb != None and ub != None:
			if lb == ub:
				bndtype.append('S')
				bounds.append(lb)
			if lb == -ub and lb != 0:
				bndtype.append('D') # This complies with how GLPKMEX works, but normally it cannot occur
				bounds.append(ub)

	mat = numpy.zeros((rows-1,cols))

	m = lp.matrix
	
	for i in m:
		if i[0] > 0:
			mat[i[0]-1,i[1]] = i[2]
	
	# The output in the format
	#      min c x
	# s.t. A x < = > b
	#      x <= ub
	#      x >= lb
	
	results = {}
	results['A'] = mat
	results['b'] = numpy.matrix(bounds).T
	results['c'] = numpy.array(obj)
	results['ctype'] = numpy.matrix(bndtype)
	results['vartype'] = numpy.matrix(vartype)
	results['lb'] = numpy.array(lbound)
	results['ub'] = numpy.array(ubound)
	
	output = sys.argv[1]
	output = output.rpartition('.')
	output = output[0] + '.mat'
	
	scio.savemat(output,results,oned_as='row')
