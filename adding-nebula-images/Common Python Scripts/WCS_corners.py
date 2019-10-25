# -*- coding: utf-8 -*-
from astropy.io import fits
import astropy.wcs as wcs
import sys
import re
import math

filename = sys.argv[-1]
#filename = 'D:\Glenn\Downloads\wcs (2).fits'
hdulist = fits.open(filename)
w = wcs.WCS(hdulist[(0)].header, hdulist)
hdu = hdulist[0]
hdr = hdulist[0].header
hdulist.close()

print(repr(w))

print('Image Width x Height:',hdu.header['IMAGEW'],'x', hdu.header['IMAGEH'])
for comment in hdr['comment']:
    #print(comment)
    if re.match('^scale:',comment):
            print(comment)

cd11 = hdu.header['CD1_1']
cd12 = hdu.header['CD1_2']
cd21 = hdu.header['CD2_1']
cd22 = hdu.header['CD2_2']
if cd11 * cd22 - cd12 * cd21 > 0:
    parity = 1
else:
    parity = -1

print('Image Parity: ',parity)
orientation = math.degrees(math.atan2(cd21-cd12, cd11+cd22))
print('Image Orientation: {0:.1f}'.format(180 + orientation),'East of North')

wx1, wy1 = w.all_pix2world(0., 0., 0)
#print('0,0: {0} {1}'.format(wx1, wy1)) 

wx2, wy2= w.all_pix2world(hdu.header['IMAGEW']-1,0, 0)
#print(hdu.header['IMAGEW']-1,0,': {0} {1}'.format(wx2, wy2))


wx3, wy3 = w.all_pix2world(hdu.header['IMAGEW']-1, hdu.header['IMAGEH']-1, 0)
#print(hdu.header['IMAGEW']-1, hdu.header['IMAGEH']-1,': {0} {1}'.format(wx3, wy3))

wx4, wy4 = w.all_pix2world(0., hdu.header['IMAGEH']-1, 0)
#print(0, hdu.header['IMAGEH']-1,': {0} {1}'.format(wx4, wy4))
print('\nworld coordinates of image corners for Stellarium:')
print('\n"worldCoords" : [[[{0:.4f}, {1:.4f}], [{2:.4f}, {3:.4f}], [{4:.4f}, {5:.4f}], [{6:.4f}, {7:.4f}]]],'.format(wx4, wy4, wx3, wy3, wx2, wy2, wx1, wy1))
#print('Press Enter to exit')
#input()
