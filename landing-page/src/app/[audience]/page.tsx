import { notFound } from "next/navigation";
import LandingTemplate from "../../components/LandingTemplate";
import { landingContent } from "../../data/landing-content";

// Define the params type correctly for Next.js App Router dynamic routes
type Props = {
  params: Promise<{ audience: string }>;
};

export function generateStaticParams() {
  return Object.keys(landingContent).map((audience) => ({
    audience,
  }));
}

export default async function AudiencePage({ params }: Props) {
  const resolvedParams = await params;
  const audience = resolvedParams.audience;
  const content = landingContent[audience];

  if (!content) {
    notFound();
  }

  return <LandingTemplate {...content} audienceId={audience} />;
}
