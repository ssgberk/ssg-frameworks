import React from 'react';
import {PageMetadata} from '@docusaurus/theme-common';
import LayoutProvider from '@theme/Layout/Provider';

// Bare layout: theme providers (color mode etc.) but no navbar, footer or sidebar chrome.
export default function Layout({children, title, description}) {
  return (
    <LayoutProvider>
      <PageMetadata title={title} description={description} />
      <main>{children}</main>
    </LayoutProvider>
  );
}
