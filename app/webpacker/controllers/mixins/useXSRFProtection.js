export const useXSRFProtection = (controller) => {
  Object.assign(controller, {
    getXSRFCookieValue(cookie) {
      return cookie
        .split("; ")
        .find((row) => row.startsWith("XSRF-TOKEN"))
        ?.split("=")[1];
    },
  });
};
