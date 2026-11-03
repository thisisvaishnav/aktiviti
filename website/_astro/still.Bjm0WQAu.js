export const w = (fn) => {
  if (typeof fn === 'function' && !document.hidden) {
    fn();
  }
};
export default { w };
