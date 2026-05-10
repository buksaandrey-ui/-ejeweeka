const fs = require('fs');

const file = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/LandingTemplate.tsx';
let content = fs.readFileSync(file, 'utf8');

// Add imports
if (!content.includes('LandingTailA')) {
  content = content.replace(
    'export default function LandingTemplate(props: LandingTemplateProps & { audienceId: string }) {',
    `import LandingTailA from './tails/LandingTailA';
import LandingTailB from './tails/LandingTailB';
import LandingTailC from './tails/LandingTailC';

export default function LandingTemplate(props: LandingTemplateProps & { audienceId: string }) {`
  );
}

// Add conditional rendering
const bentoRegex = /\{\/\* БЛОК 8\.5: Premium Bento Grid \*\/\}[\s\S]*/;
const match = content.match(bentoRegex);

if (match) {
  let defaultTail = match[0];
  // Extract just the JSX part, skipping the final closing tags
  defaultTail = defaultTail.replace(/<\/>\n\s*\);\n\}\s*$/, '');
  
  content = content.replace(
    bentoRegex,
    `{props.tailVariant === 'A' && <LandingTailA {...props} />}
      {props.tailVariant === 'B' && <LandingTailB {...props} />}
      {props.tailVariant === 'C' && <LandingTailC {...props} />}
      {(!props.tailVariant || props.tailVariant === 'default') && (
        <>
          ${defaultTail}
        </>
      )}
    </>
  );
}
`
  );
  
  fs.writeFileSync(file, content);
  console.log("Successfully patched LandingTemplate.tsx");
} else {
  console.log("Could not find bento block.");
}
