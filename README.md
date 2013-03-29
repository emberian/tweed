tweed
=====

[![travis-ci status](https://secure.travis-ci.org/cmr/tweed.png)](http://travis-ci.org/#!/cmr/tweed/builds)

tweed is a lua web framework. It takes a table to describe URL routes, rather
than a bunch of patterns (as you would do in django or rails, for example).
In the tradition of "microframeworks" it doesn't offer a templating system or
a database access layer.

While not strictly being MVC, or any other such acronym, the functions which
are called by the framework when a request comes in are named "controllers".
Controllers are provided in a table. tweed uses [leafy][] internally, so
looking at its README might be useful. An example:

```lua
tweed.make_site {
	about = function(context)
		context.response:text("the about page")
	end
}
```

That function will be called when any request is made to `/about`.
What about just `/`? Simple:

```lua
tweed.make_site { 
	[""] = function(context) ... end
}
```

Nesting is of course possible:

```lua
tweed.make_site {
	about = setmetatable({
		legal = functiom(context) ... end
		}, { __call = function(context) ... end}
	)
}
```

The metatable is required for `/about` to still be served.

The examples so far respond to every HTTP method. To respond only to a
specific or subset of events:

```lua
tweed.make_site {
	signup = {
		[tweed.GET] = function(context) ... end,
		[tweed.POST] = function(context) ... end
	}
}
```

tweed currently only supports GET, POST, PUT, and DELETE, but more can
easily be added. If you want the ability to register custom HTTP methods,
open an issue and I'll add it in.

What use would a web framework be without variable routes? So, for example:

```lua
tweed.make_site {
	person = {
		[tweed.int "id"] = function(context)
			context.response:text("request personed " .. context.params.id)
		end
	}
}
```

In this case, paths such as `/person/42` will be matched, but `/person/me`
will not. Also available is `tweed.string` and `tweed.any`. It's easy to
make your own "filter functions" for the routing, though. Any callable that
is a key is called when no explicit path matches. The callable must be a
table that has a `name` field. This field is the name that will be assigned
to in `context.params`, which holds all the matched parameters.
`context.params._unmatched` is a sequence of the remaining unmatched
parameters.

The context table has a `request` and `response` field, and also a
`wsapi_env` field for any case where the request and response aren't enough.

At least, in theory. Until 0.1, any or none of these features are stable or
implemented at all.

Further documentation forthcoming.

[leafy]: https://github.com/cmr/leafy
