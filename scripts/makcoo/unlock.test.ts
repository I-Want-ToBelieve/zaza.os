#!/usr/bin/env -S deno run --allow-all


import { unlock } from './fn.ts'

await unlock('192.168.0.100')

Deno.exit(0)
