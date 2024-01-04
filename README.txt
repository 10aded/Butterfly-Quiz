CURRENTLY IN DEVELOPMENT, NOT YET READY FOR RELEASE

This is a simple quiz game / app to help its authors learn common butterflies native to North America.

The project can be build / run with the command

    zig build run

called from within the top directory.

All photos in the project are from Wikimedia Commons, and as such they have all be released under various Creative Commons / Public Domain licenses. Links to the sources of these photos, their authors, and to the photo licenses can be found in the file:

    photo-source-license-links.csv

The list of butterflies was taken from the book "Familiar Butterflies of North America" (National Audubon Society, 1990, Knopf, ISBN: 978-0-679-72981-5). By default, the order of butterflies that appear in the quiz are randomized, but if they were done sequentially (as per the .csv file), they would appear as they appear sequentially in the book.

The project is written in Zig using the raylib library, specifically commit number 710e81, part of which is included in the project in the raylib directory.

Raylib is created by github user Ray (@github handle raysan5) and available at:

    https://github.com/raysan5

See the page above for full license details.

The entire development of this app (basically) can be found on YouTube at:

    https://www.youtube.com/@10aded

