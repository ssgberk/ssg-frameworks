import React from "react"
import { graphql } from "gatsby"

import Header from '../components/Header'
import '../css/style.css'

const Post = ({ data }) => {
  const post = data.markdownRemark

  return (
    <div>
      <Header title={data.site.siteMetadata.title} />
      <div>
        <h1>{post.frontmatter.title}</h1>
        <p>{post.frontmatter.date}</p>
        <div dangerouslySetInnerHTML={{ __html: post.html }} />
      </div>
    </div>
  )
}

export default Post

export const query = graphql`
  query PostQuery($id: String!) {
    site { siteMetadata { title } }
    markdownRemark(id: { eq: $id }) {
      html
      frontmatter {
        title
        date(formatString: "DD MMMM, YYYY")
      }
    }
  }
`
