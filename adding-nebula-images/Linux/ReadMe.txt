Assuming you are using some flavor of a Gnome desktop, you can use the files in this directory as drag and drop icons that will 
run the python scripts on your dropped files.

These two .desktop files should be placed on your desktop, or wherever you keep astro imaging tools. You will have to set the files to have
execute permission (chmod 755 or by using your desktop properties/permissions GUI).

You can then drag and drop one or more images on the Stellarium_Nebulae_Image_Prep desktop icon, or one or more wcs.fits files
on the WCS_corners desktop icon and the Python scripts will run for each dropped file.

One significant caveat is that filenames containing spaces don't seem to work. If by chance you can modify the desktop files to 
make it work (in a way that doesn't have paths specific to your particular case) please let me know!
