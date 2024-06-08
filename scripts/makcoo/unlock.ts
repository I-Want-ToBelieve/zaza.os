
import { computer } from './computer.ts'
import { lock } from './fn.ts'

if (Deno.args.length === 0) Deno.exit(1)

const room = Deno.args.at(0)

const the_room = computer.find(it => it.room === room)

if (the_room) Deno.exit(1)

await Promise.all(the_room.hosts.map(it => unlock(it)))

Deno.exit(0)
