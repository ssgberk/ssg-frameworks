import { useData } from 'vike-react/useData';

export default function Page() {
  const { title, html } = useData();
  return (
    <>
      <h1>{title}</h1>
      <div dangerouslySetInnerHTML={{ __html: html }} />
    </>
  );
}
