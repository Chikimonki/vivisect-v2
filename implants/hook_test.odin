package main

import "core:c"

@(export)
hooked_function :: proc "c" () -> c.int {
    return 42
}
