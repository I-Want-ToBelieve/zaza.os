export const computer = Array.from({ length: 10 }, (it, idx) => {
  const room = idx + 1
  return {
    room,
    hosts: Array.from({ length: 10 }, (_, idx_) => {
      return `192.168.${room}${idx_}`
    }),
  }
})


