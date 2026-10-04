import React from 'react'
import { graphql } from 'gatsby'

import Header from '../components/Header'
import PostList from '../components/PostList'
import '../css/style.css'

const IndexPage = ({ data }) =>
  <div>
    <Header title={data.site.siteMetadata.title} />
    <div>
      <b>News 'n' Updates</b>
      <PostList posts={data.allMarkdownRemark.nodes} />
    </div>
  </div>

export default IndexPage

export const query = graphql`
  query IndexQuery {
    site { siteMetadata { title } }
    allMarkdownRemark(sort: { frontmatter: { date: DESC } }) {
      nodes {
        id
        frontmatter { title }
        fields { slug }
      }
    }
  }
`
