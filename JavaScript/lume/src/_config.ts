import lume from "lume/mod.ts";

const site = lume({
  src: "./site",
  dest: "./_site",
});

site.add("assets");

export default site;
