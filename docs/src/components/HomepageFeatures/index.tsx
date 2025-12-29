import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Julia-first workflow',
    Svg: require('@site/static/img/julia-dots.svg').default,
    description: (
      <>
        Build web apps directly in Julia with automatic interactivity.
      </>
    ),
  },
  {
    title: 'Zero-frontend setup',
    Svg: require('@site/static/img/zero-setup.svg').default,
    description: (
      <>
        Create full web interfaces without writing HTML, CSS, or JavaScript.
      </>
    ),
  },
  {
    title: 'High-performance data apps',
    Svg: require('@site/static/img/high-perf.svg').default,
    description: (
      <>
        Handle large data and complex computations with Julia’s performance.
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
