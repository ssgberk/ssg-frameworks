const path = require(`path`)

exports.onCreateNode = ({ node, actions, getNode }) => {
  if (node.internal.type === `MarkdownRemark`) {
    const fileNode = getNode(node.parent)
    actions.createNodeField({ node, name: `slug`, value: fileNode.name })
  }
}

exports.createPages = async ({ graphql, actions }) => {
  const result = await graphql(`
    {
      allMarkdownRemark {
        nodes {
          id
          fields {
            slug
          }
        }
      }
    }
  `)
  if (result.errors) throw result.errors
  result.data.allMarkdownRemark.nodes.forEach(node => {
    actions.createPage({
      path: `/posts/${node.fields.slug}/`,
      component: path.resolve(`./src/templates/post.js`),
      context: { id: node.id },
    })
  })
}
