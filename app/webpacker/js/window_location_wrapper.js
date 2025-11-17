// Wrapper around location window.location
//
// It's mainly needed because we can't mock window.location in jsdom
//
const locationPathName = (pathName) => {
  window.location.pathname = pathName;
};

export { locationPathName };
