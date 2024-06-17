import $ from 'https://deno.land/x/dax/mod.ts'

export const lock = async (ip: string) => {
  console.log(ip)
  return $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${ip} "loginctl lock-sessions"'`
}

export const unlock = async (ip: string) => {
  console.log(ip)
  return $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${ip} "loginctl unlock-sessions"'`
}

export const wakeup = async (mac: string) => {
  return await $`sh -c ', wol ${mac}'`
}

export const cmd = async (it: any, cmd: string) => {
  const string = `sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${it.ip} "${cmd}"'`
  console.log(string)
  return $`${string}`
}

export const sleep = async (ip: string) => {
  console.log(`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${ip} "systemctl suspend"'`)
  return $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${ip} "systemctl suspend"'`
}


export const rebuild = async (ip: string) => {
  return await $`cd ../../;pwd;sh -c 'sudo nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@${ip}'`
}
