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
[CBQ::Model::Region](lib/CBQ/Model/Region.pm)'s `cms_update` method for details.

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

## Instructions for Regional Sub-Site Repositories

Each region is setup with a region repository. The structure of each region's
repository is the same. There are up to 3 sub-directories in each repository:
`config`, `docs`, and `static`.

### Markdown Documents

Let's start with `docs`. The `docs` directory contains a directory structure of text
files in Markdown format. Markdown is a simple pure-text way to structure web
documents that's both easily to read as code.

Take a look at the
[policies and governance file for WWA](https://github.com/gryphonshafer/cbqz-wwa/blob/master/docs/policies_and_governance/hosting.md?plain=1).

You can click "Preview" to see what this code will render to, and you can
[see what it looks like on the CBQ web site](https://wwa.cbqz.org/policies_and_governance/hosting.md).

Note that the system adds a navigation bar (either left side on desktops or a
"hamburger" menu on phones), header and footer content, and photos. Photos are
kept in a single pool, and when the page loads, the system will automatically
and randomly select a photo for the upper-right and 3 for the footer. (The photo
in the upper-right is not included on small screens, though.)

Take a look at the
[home page code for WWA](https://github.com/gryphonshafer/cbqz-wwa/blob/master/docs/index.md?plain=1).

From time to time, a page will visually look better if the upper-right photo
isn't included. The home page of WWA does this with the comment on line 1. Line
2 uses HTML to insert an image. Another thing to note is that links are assumed
to be relative or absolute to your region. If you want to link to a page that's
part of the main CBQ site, prefix the link with an asterisk.

For file and directory names, use all lower-case with underscores separating the
words. The system reads through the `docs` directory tree and builds the
navigation menu based on the names of directories and files. If you prefix a
file or directory name with an underscore, the system will ignore it for the
purposes of building the menu. (You can still link to it, though.)

You'll notice there are some automatically inserted links under "Meets and
Rules" that the system handles for you. Most of the rest of the content is up to
you in your own region's repository.

### Configuration YAML

Now let's look at the `config` directory tree. This is where we have data files
that describe things, mostly about meets. You can organize these files however
you'd like; the system just reads everything and merges it all together. The
files are in YAML format, which is similar to Markdown in that it's simple,
non-nerd-readable (mostly), and can express complex data organization.

Take a look at
[WWA's YAML from the 2025-2026 Corinthians season](https://github.com/gryphonshafer/cbqz-wwa/blob/master/config/seasons/2025_cor.yaml).

Each block there describes a meet. You can likely intuit what a meet will need
to be defined as by looking at the examples in this file; however, please feel
free to ask me for assistance. It's easy once you understand all of the nuance
of all the settings, but that understanding takes some time to learn.

Lastly, the static directory is a place to put things like PDFs or other things
to download. These can be linked to from pages in the docs directory.
