import {
  $,
  async,
  cd,
  fs,
  io,
  path
} from 'https://deno.land/x/dzx@0.4.0/mod.ts'

import { schools } from './computer.ts'
import { wakeup } from './fn.ts'

if (Deno.args.length === 0) Deno.exit(1)

const room = Deno.args.at(0)
console.log('room', room)
const the_room = schools.find(it => String(it.room) === String(room))
console.log('the_room', the_room)
if (!the_room) Deno.exit(1)

await Promise.allSettled(the_room.hosts.map(it => wakeup(it.mac)))

Deno.exit(0)
