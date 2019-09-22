/////////////
// for more metalsmith examples (sites) using nunjucks see:
//   - https://github.com/micahgodbolt/micahcodes


var Metalsmith  = require('metalsmith');
var markdown    = require('metalsmith-markdown');
var layouts     = require('metalsmith-layouts');
var inplace     = require('metalsmith-in-place');
var metadata    = require('metalsmith-metadata');
var collections = require('metalsmith-collections');
var permalinks  = require('metalsmith-permalinks');
var nunjucks    = require('nunjucks');

// hack: there must be a better builtin/standard way w/o custom plugin ??
var addurlxx = function (options) {
  return function( files, metalsmith, done ) {
  // console.log(files);
  // console.log(metalsmith);
  // console.log( metalsmith._metadata.site.base_url );

  // Loop through files
  Object.keys(files).forEach( function(file) {
    var file_data = files[file];
    file_data.urlxx = metalsmith._metadata.site.base_url + file;
    // console.log( file_data );
    console.log( file_data.urlxx );
  });
  
  done();      
}};


// Note: Need to add configuration to nunjucks that metalsmith cannot
nunjucks
  .configure( 'layouts', {watch: false, noCache: true}); 


metalsmith = Metalsmith(__dirname)
  .use(metadata({
    site:  'site.json',
    links: 'data/links.json'
  }))
  .use(collections({
      posts: {
        pattern: 'posts/**/*.md',
        sortBy: 'date',
        reverse: true
      }}))
  .use(markdown())
  .use(addurlxx())
//  .use(permalinks({
//        pattern: ':path.html'
//    }))
  .use(inplace({
    engine: 'nunjucks',
    pattern: '**/*.html'
  }))
  .use(layouts({
    engine: 'nunjucks',
    pattern: '**/*.html',
    directory: 'layouts'
  }))
  .use(function(files, metalsmith, done) {
    console.log(files);
    console.log(metalsmith);
    done();
  })
  .build(function(err){
    if (err) throw err;
  });
