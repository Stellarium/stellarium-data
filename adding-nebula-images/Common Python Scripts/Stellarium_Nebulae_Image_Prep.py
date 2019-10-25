# -*- coding: utf-8 -*-
"""
Created on Sun Aug 25 18:19:14 2019

@author: Glenn C. Newell
"""
import warnings
warnings.filterwarnings(action="ignore")
from astroquery.astrometry_net import AstrometryNet
import astropy.wcs as wcs
import re
import math
from PIL import Image, ImageOps
import os
import sys



def flip_image(image_path, saved_location):
    """
    Flip or mirror the image
 
    @param image_path: The path to the image to edit
    @param saved_location: Path to save the cropped image
    """
    image_obj = Image.open(image_path)
    rotated_image = image_obj.transpose(Image.FLIP_LEFT_RIGHT)
    rotated_image.save(saved_location)
    rotated_image.show()

ast = AstrometryNet()
ast.api_key = 'XXXXXXXXXXXXXXXX'

imagename = sys.argv[1]
#image.show()
#imagename = "D:/Google Drive/Stellarium DSO image addition/buble_full_P-1.jpg"
file, ext = os.path.splitext(imagename)
image = Image.open(imagename)
print('Unstretching image by raising blackpoint (for Plate Solving)')
greyscale = image.copy().convert('L')

stars = ImageOps.colorize(greyscale, black="black", white="white", blackpoint=200, whitepoint=255)
#stars.show()
print('Saving:', file + '_stars.jpg' )
stars.save(file + '_stars.jpg')
print('Uploading:', file + '_stars.jpg' )

#wcs_header = ast.solve_from_image('D:\Google Drive\Stellarium DSO image addition\buble_full_P-1.jpg', force_image_upload=True)

try_again = True
submission_id = None

while try_again:
    try:
        if not submission_id:
            #"C:\Users\gnewell\Google Drive\Stellarium DSO image addition\buble_full_P-1.jpg"
            #"D:/Google Drive/Stellarium DSO image addition/buble_full_P-1.jpg"
            wcs_header = ast.solve_from_image(file + '_stars.jpg' , force_image_upload=True, parity=2, scale_units='degwidth', scale_type='ul',
                                              scale_lower=0.1, scale_upper=12.0, solve_timeout=620, downsample_factor=2, submission_id=submission_id)
        else:
            wcs_header = ast.monitor_submission(submission_id,
                                                solve_timeout=600)
    except TimeoutError as e:
        submission_id = e.args[1]
    else:
        # got a result, so terminate
        try_again = False

if wcs_header:
    # Code to execute when solve succeeds
    #print(wcs_header)
    #w = wcs_header
    w = wcs.WCS(wcs_header)
    #hdu = hdulist[0]
    #hdr = hdulist[0].header
    #hdulist.close()
    
    #print(repr(wcs_header))
    
    print('\nImage Width x Height:',wcs_header['IMAGEW'],'x', wcs_header['IMAGEH'])
    for comment in wcs_header['comment']:
        #print(comment)
        if re.match('^scale:',comment):
            print(comment)
            l = []
            for t in comment.split():
                try:
                    l.append(float(t))
                except ValueError:
                    pass
            scale = l[-1]
            #print(scale)
    
    cd11 = wcs_header['CD1_1']
    cd12 = wcs_header['CD1_2']
    cd21 = wcs_header['CD2_1']
    cd22 = wcs_header['CD2_2']
    if cd11 * cd22 - cd12 * cd21 > 0:
        parity = 1
    else:
        parity = -1
    
    print('Image Parity: ',parity)
    orientation = math.degrees(math.atan2(cd21-cd12, cd11+cd22))
    print('Image Orientation: {0:.1f}'.format(180 + orientation),'East of North')
    
    #print('Press Enter to exit')
    #input()

else:
    print('Failure to solve input image')
    # Code to execute when solve fails
    raise SystemExit
imgresized = image.copy()
rescale = 1.0
if scale < 1.0:
    rescale = 0.5
    if scale < 0.5:
        rescale = 0.25
    size = int(rescale * int(wcs_header['IMAGEW'])), int(rescale * int(wcs_header['IMAGEH']))
    imgresized = image.resize(size)
    
imgflipped = imgresized.copy()
if parity == -1:
    print('Flipping image to correct Parity')
    imgflipped.transpose(Image.FLIP_LEFT_RIGHT)
#image2.show()
ccw = 180.01 - orientation
print('Rotating image',ccw, 'ccw so North is Up')
imgrotated = imgflipped.rotate(ccw, expand=1)
#imgrotated.show()
width, height = imgrotated.size
print('New size: ',width, height)
if width >= height:
    ledgewidth = True
    ledgeheight = False
else:
    ledgewidth = False
    ledgeheight = True
scaledone = False
print('Scaling long edge to 512, 1024, or 2048')
if ledgewidth == True:
    if width > 2048:
        rescale2 = 2048 / width
        size = int(rescale2 * width), int(rescale2 * height)
        imgreresized = imgrotated.resize(size)
        scaledone = True
    if (scaledone == False) and (width > 1024):
        rescale2 = 1024 / width
        size = int(rescale2 * width), int(rescale2 * height)
        imgreresized = imgrotated.resize(size)
        scaledone = True
    if scaledone == False:
        rescale2 = 512 / width
        size = int(rescale2 * width), int(rescale2 * height)
        imgreresized = imgrotated.resize(size)
        scaledone = True
if ledgeheight == True:
    if height > 2048:
        rescale2 = 2048 / height
        size = int(rescale2 * width), int(rescale2 * height)
        imgreresized = imgrotated.resize(size)
        scaledone = True
    if scaledone == False and height > 1024:
        rescale2 = 1024 / height
        size = int(rescale2 * width), int(rescale2 * height)
        imgreresized = imgrotated.resize(size)
        scaledone = True
    if scaledone == False:
        rescale2 = 512 / height
        size = int(rescale2 * width), int(rescale2 * height)
        imgreresized = imgrotated.resize(size)
        scaledone = True
#imgreresized.show()
width, height = imgreresized.size
print('New size: ',width, height) 
print('Padding short edge to 512, 1024, or 2048')
paddone = False
delta_w = 0
delta_h = 0
if ledgewidth == True:
    if height > 1024:
        delta_h = 2048 - height
        paddone = True
    if paddone == False and height > 512:
        delta_h = 1024 - height
        paddone = True
    if paddone == False:
        delta_h = 512 - height
if ledgeheight == True:
    if width > 1024:
        delta_w = 2048 - width
        paddone = True
    if paddone == False and width > 512:
        delta_w = 1024 - width
        paddone = True
    if paddone == False:
        delta_w = 512 - width
padding = (delta_w//2, delta_h//2, delta_w-(delta_w//2), delta_h-(delta_h//2))
finalimage = ImageOps.expand(imgreresized, padding)
width, height = finalimage.size
print('Final size: ',width, height) 
#finalimage.show()  
print('Saving final image:', file + '_for_Stellarium.png')
finalimage.save(file + '_for_Stellarium.png')   
print('Unstretching image by raising blackpoint (for Plate Solving)')
greyscale = finalimage.copy().convert('L')

stars = ImageOps.colorize(greyscale, black="black", white="white", blackpoint=200, whitepoint=255)
#stars.show()
print('Saving:', file + '_for_Stellarium_stars.jpg' ) 
stars.save(file + '_for_Stellarium_stars.jpg')    
try_again = True
submission_id = None
newscale = scale / rescale / rescale2

newll = newscale * width /3600 / 1.2
newul = newscale * width /3600 * 1.2
print('Scale est:',newscale,'arcsecperpix (for Plate Solving) Lower Limit:', newll, 'Upper Limit:', newul, 'degwidth')
print('Uploading:', file + '_for_Stellarium_stars.jpg')
while try_again:
    try:
        if not submission_id:
             #wcs_header2 = ast.solve_from_image(file + '_for_Stellarium_stars.jpg', force_image_upload=True, parity=0, scale_units='arcsecperpix', scale_type='ev',
             #                                 solve_timeout=620, scale_est=newscale,  scale_err=20, downsample_factor=2, submission_id=submission_id)
             wcs_header2 = ast.solve_from_image(file + '_for_Stellarium_stars.jpg', force_image_upload=True, parity=1, scale_units='degwidth', scale_type='ul',
                                              solve_timeout=620, scale_lower=newll, scale_upper=newul, downsample_factor=2, submission_id=submission_id)
        else:
            wcs_header2 = ast.monitor_submission(submission_id,
                                                solve_timeout=600)
    except TimeoutError as e:
        submission_id = e.args[1]
    else:
        # got a result, so terminate
        try_again = False

if wcs_header2:
    w2 = wcs.WCS(wcs_header2)
    # Code to execute when solve succeeds  
    wx1, wy1 = w2.all_pix2world(0., 0., 0)
    #print('0,0: {0} {1}'.format(wx1, wy1)) 
    
    wx2, wy2= w2.all_pix2world(wcs_header2['IMAGEW']-1,0, 0)
    #print(wcs_header2['IMAGEW']-1,0,': {0} {1}'.format(wx2, wy2))
    
    
    wx3, wy3 = w2.all_pix2world(wcs_header2['IMAGEW']-1, wcs_header2['IMAGEH']-1, 0)
    #print(wcs_header2['IMAGEW']-1, wcs_header2['IMAGEH']-1,': {0} {1}'.format(wx3, wy3))
    
    wx4, wy4 = w2.all_pix2world(0., wcs_header2['IMAGEH']-1, 0)
    #print(0, wcs_header2['IMAGEH']-1,': {0} {1}'.format(wx4, wy4))
    i_n = '\"' + os.path.basename(file + '_for_Stellarium.png') + '\",'
    print('\nSaving Entry for Stellarium textures.json in:',file + '_for_Stellarium.json')
    if os.path.exists(file + '_for_Stellarium.json'):
        os.remove(file + '_for_Stellarium.json')
    json = open(file + '_for_Stellarium.json', "a")
    print('\t{\n\t\t\"imageCredits\" : {\"Short\": \"Mine\", \"infoUrl\": \"\"},\n\t\t\"imageUrl\" :',i_n, file=json)
    print('\t\t\"worldCoords" : [[[{0:.4f}, {1:.4f}], [{2:.4f}, {3:.4f}], [{4:.4f}, {5:.4f}], [{6:.4f}, {7:.4f}]]],'.format(wx4, wy4, wx3, wy3, wx2, wy2, wx1, wy1), file=json)
    print('\t\t\"textureCoords\" : [[[0,0], [1,0], [1,1], [0,1]]],\n\t\t\"minResolution\" : 0.2,\n\t\t\"maxBrightness\" : 12.0\n\t},', file=json)
    json.close()
else:
    print('Failure to solve final image')
    # Code to execute when solve fails
	