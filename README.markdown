# Systatic: Static Site Authoring Tool in NodeJS

Inspired by [Middleman](http://middlemanapp.com), this Node.js toolchain is written with [Bricks](http://bricksjs.com) and [Servitude](https://github.com/JerrySievert/servitude), to allow the quick authoring if static web apps.

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

```
systatic build
```

## Test

Once your static files are built and compressed, you can test out the files output in the `build` directory with the `test` command. This just runs a static server on the same development port in your `config.json` file.

```
systatic test
```

## Deploy

_Coming soon..._

With that generated static content, next you'll want to deploy.

```
systatic deploy
```