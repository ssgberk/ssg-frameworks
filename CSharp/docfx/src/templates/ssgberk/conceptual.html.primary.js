exports.transform = function (model) {
  var path = model._path || '';
  model.isIndex = path === 'index.html';
  model.isNotFound = path === '404.html';
  model.isPost = !model.isIndex && !model.isNotFound;
  if (model.isPost) {
    model.pageTitle = model.title + ' | SSGBerk Reference';
    model.day = (model.date || '').substring(0, 10);
  } else if (model.isNotFound) {
    model.pageTitle = 'Page not found | SSGBerk Reference';
  } else {
    model.pageTitle = 'SSGBerk Reference';
    var posts = model.posts || [];
    for (var i = 0; i < posts.length; i++) {
      posts[i].day = String(posts[i].date).substring(0, 10);
    }
  }
  return model;
};
