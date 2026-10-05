import nextra from 'nextra';

const withNextra = nextra({ search: false });

export default withNextra({ output: 'export', trailingSlash: true, images: { unoptimized: true } });
