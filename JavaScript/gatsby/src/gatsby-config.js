module.exports = {
  siteMetadata: {
    title: "Gatsby (+GraphQL) Stay Static Site Sample",
  },
  plugins: [
    {
      resolve: `gatsby-source-filesystem`,
      options: {
        name: `posts`,
        path: `${__dirname}/src/pages/posts`,
      },
    },
    `gatsby-transformer-remark`,
  ],
}
