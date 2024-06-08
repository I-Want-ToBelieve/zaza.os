#!/usr/bin/env -S deno run --allow-all


import { lock } from './fn.ts'

await lock('192.168.0.100')

Deno.exit(0)
