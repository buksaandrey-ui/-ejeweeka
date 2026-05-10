const fs = require('fs');
const path = require('path');

const sourcePath = path.join(__dirname, 'src', 'app', 'page.tsx');
const content = fs.readFileSync(sourcePath, 'utf8');

const variants = [
  {
    dir: 'variant1',
    name: 'Variant1Page',
    primary: '#7C3AED',
    primaryRgba: '124,58,237',
    gradStart: '#5B21B6',
    gradMid: '#7C3AED',
    gradEnd: '#A78BFA',
    hueRotate: '240deg'
  },
  {
    dir: 'variant2',
    name: 'Variant2Page',
    primary: '#4C1D95',
    primaryRgba: '76,29,149',
    gradStart: '#2E1065',
    gradMid: '#4C1D95',
    gradEnd: '#8B5CF6',
    hueRotate: '260deg'
  },
  {
    dir: 'variant3',
    name: 'Variant3Page',
    primary: '#9333EA',
    primaryRgba: '147,51,234',
    gradStart: '#6B21A8',
    gradMid: '#9333EA',
    gradEnd: '#D8B4FE',
    hueRotate: '250deg'
  }
];

variants.forEach(v => {
  let newContent = content;
  
  // Replace primary color
  newContent = newContent.replace(/#F5922B/g, v.primary);
  
  // Replace rgba variations of primary
  newContent = newContent.replace(/245,146,43/g, v.primaryRgba);
  
  // Replace gradient
  newContent = newContent.replace(/#E85D04/g, v.gradStart);
  newContent = newContent.replace(/#FFB347/g, v.gradEnd);
  
  // Rename component
  newContent = newContent.replace(/export default function HomePage\(\) {/, `export default function ${v.name}() {`);
  
  // Add CSS filter to images to change orange to purple
  newContent = newContent.replace(/<Image/g, `<Image style={{ filter: "hue-rotate(${v.hueRotate})" }}`);
  // Fix the double style tag issue if an image already had a style prop
  // The original has: style={{ height: 'auto' }} or style={{ maxWidth: "min(600px, 80vw)", height: "auto" }}
  // We'll use a regex to merge style props if needed, or just append filter to existing style
  newContent = newContent.replace(/style={{([^}]+)}}/g, (match, innerStyle) => {
    if (innerStyle.includes('filter:')) return match;
    if (match.includes('hue-rotate')) return match; // already injected
    return `style={{ ${innerStyle}, filter: "hue-rotate(${v.hueRotate})" }}`;
  });
  
  // Some images don't have style prop, the <Image style={{ filter: ... }} replacement above handles it 
  // but it might create duplicate styles if there was already one. 
  // Let's do a cleaner regex approach:
  // Instead of the naive replacement, we'll undo it and do it better.
});
