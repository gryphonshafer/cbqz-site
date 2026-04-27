# CBQ Web Site

[![test](https://github.com/gryphonshafer/cbqz-site/workflows/test/badge.svg)](https://github.com/gryphonshafer/cbqz-site/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/cbqz-site/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/cbqz-site)

This is the software and content for the [CBQ](https://cbqz.org) web site.

## Installation and Setup

This project requires the [Omniframe](https://github.com/gryphonshafer/omniframe)
project, which is expected to be deployed in a parallel directory. Follow the
instructions in the Omniframe README "Installation" and "Project Setup" sections.

## Run Application

To run the project application, follow the instructions in the `~/app.psgi`
file within this project's root directory.

## Regional CMS Content Automatic Update

When regional CMS content is pushed to the configuration-specified branch, a
webhook may be configured for that region. Read the documentation for
[CBQ::Model::Region](blob/master/lib/CBQ/Model/Region.pm)'s `cms_update` method
for details.

## Photo Optimization

Within `~/static/photos` reside many JPG photo image files. These are
automatically picked up and displayed at random across most rendered pages.
Use the following procedure to optimize photos prior to add/commit:

    for file in $( ls *.{jpg,png,gif} 2> /dev/null )
    do
        name=$(echo $file | sed 's/\.[^\.]*$//')
        convert $file -resize 440\> $name.jpg
    done
    rm *.{png,gif}
    jpegoptim -s *.jpg

Requires:

- `imagemagick`
- `jpegoptim`
