import React from 'react'
import { Link } from 'gatsby'

export default ({ title }) =>
  <div id="header">
    <Link to="/">{title}</Link>
  </div>
