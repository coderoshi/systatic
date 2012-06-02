# Systatic: Static Site Authoring Tool in NodeJS

Inspired by [Middleman](http://middlemanapp.com), this Node.js toolchain is written with [Bricks](http://bricksjs.com) and a collection of plugins to allow the quick authoring if static web apps.

The focus here is to quickly develop and deploy apps that are heavier on CSS or Javascript, leveraging tools that allow the least amount of typing to get the job done (eg. Less, Stylus, CoffeeScript, Jade). Finally, to optimize file management so your apps load as quickly as possible (presumably via some CDN).

# Getting Started

First you need to install the systatic server. It's really just a bricksjs+servitude server with a bunch of predefined paths and templates.

```
npm install systatic -g
systatic new my_proj
cd my_proj
systatic
```

The last command runs the server, by default port 3000 (like bricks, you can change the port with `--port`).

# Configuration

The default generated project will come with a config.json file. This file defines various source and plugin combinations. Generally you should just follow the default settings, but if you wish to alter anything (for example, change the javascripts route from `/javascripts` to `/js`) change this file.

## Build

Since the point is to generate a static site, the next command you run will be `build`. This will remove the need for an app server like nodejs, and allow you to just dump the static files somewhere like CloudFront.

It orders static site building into phases, similar to larger build systems like Maven.

Stages (executing a stage executes every stage up to it):

* setup
* clean
* documents
* scripts
* styles
* merge
* test
* compress
* publish

Choosing a phase will run all attached plugins up to and including that phase.

```
systatic merge
```

Cleans the output directory, build the html resource, build the assets, and merge them into minimal files.

```
systatic test
```

Does the same thing, but then also runs any optional static integration test (currently no implementations, but considering something like QUnit)

# Coming Soon

## Publish

With that generated static content, next you'll want to deploy to some server, git repo, CDN... whatever.

```
systatic publish
```

## Hooks

I'm considering reimplementing the hard-coded plugins to work with npm plugins, which con be configured per project. This is to allow third-party plugins to add their own stage to the build/render toolchain.

## Misc

Current thoughts:

* Every action can be attached to run before/after any other action.

An example may be if someone wanted to added a function to compress a set of icons used as CSS into sprites, and pass that information into the next action (which would be bound to the compress stage).
