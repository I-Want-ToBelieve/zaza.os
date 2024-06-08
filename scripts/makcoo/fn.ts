import $ from "https://deno.land/x/dax/mod.ts";


export const lock = async  (host: string) => {
 return $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${host} "loginctl lock-session 1"'`;
}

export const unlock = async (host: string) => {
  return $`sh -c 'ssh -i ~/.ssh/thinkpad_t420s_root_id_rsa root@${host} "loginctl unlock-session 1"'`;
}
