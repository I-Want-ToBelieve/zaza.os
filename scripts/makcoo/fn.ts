import $ from "https://deno.land/x/dax/mod.ts";


export const lock = async  (host: string) => {
  console.log(host)
  return  $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${host} "loginctl lock-session 1"'`;


}

export const unlock = async (host: string) => {
  console.log(host)
 return  $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${host} "loginctl unlock-session 1"'`;


}


export const rebuild = async  (host: string) => {
  return await $`cd ../../;pwd;sh -c 'sudo nixos-rebuild switch --flake .#dell-makcoo --verbose --show-trace --impure --target-host root@${host}'`;
}
