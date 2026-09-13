import { LiveSettlements } from "@/components/live-settlements";
const protocolSteps = [
  {
    number: "01",
    title: "Sense",
    copy: "A registered device records the shipment’s temperature conditions.",
  },
  {
    number: "02",
    title: "Commit",
    copy: "The sensor commits its telemetry result on Ethereum Sepolia.",
  },
  {
    number: "03",
    title: "Attest",
    copy: "Attestcoin proves the source-chain event to Creditcoin.",
  },
  {
    number: "04",
    title: "Settle",
    copy: "Bounds releases payment or enforces the agreed penalty.",
  },
];

export default function Home() {
  return (
    <main className="app-shell">
      <div className="pressure-field pressure-field-one" />
      <div className="pressure-field pressure-field-two" />

      <nav className="topbar">
        <a className="brand" href="#" aria-label="Bounds home">
          <span className="bounds-logo" aria-hidden="true">
            <svg viewBox="0 0 42 42" role="img">
              <rect className="logo-frame" x="1" y="1" width="40" height="40" rx="5" />
              <path className="logo-bound logo-bound-top" d="M8 10 H34" />
              <path className="logo-signal" d="M8 23 H14 L18 17 L23 29 L28 21 H34" />
              <path className="logo-bound logo-bound-bottom" d="M8 33 H34" />
              <circle className="logo-node" cx="34" cy="21" r="3" />
            </svg>
          </span>
          <span>Bounds</span>
        </a>

        <button className="wallet-button" type="button">
          Connect wallet
        </button>
      </nav>

      <section className="hero-grid">
        <div className="hero-copy">
          <span className="section-label">DePIN settlement protocol</span>

          <h1>
            Every shipment
            <span> has bounds.</span>
          </h1>

          <p className="hero-intro">
            Bounds turns temperature conditions into enforceable settlement.
            Sensor telemetry is committed on Ethereum, verified through
            Attestcoin, and settled on Creditcoin.
          </p>

          <div
            className="hero-impact-trace"
            aria-label="Animated telemetry commitment and settlement path"
          >
            <svg viewBox="0 0 600 132" role="img" aria-hidden="true">
              <path className="trace-baseline" d="M20 72 H580" />
              <path
                className="trace-path"
                d="M20 72 C110 72 135 24 225 24 S335 104 420 72 S510 72 580 72"
              />
              <circle className="trace-node trace-node-one" cx="20" cy="72" r="7" />
              <circle className="trace-node trace-node-two" cx="300" cy="57" r="7" />
              <circle className="trace-node trace-node-three" cx="580" cy="72" r="7" />
              <circle className="trace-runner" r="6">
                <animateMotion
                  dur="4.8s"
                  repeatCount="indefinite"
                  path="M20 72 C110 72 135 24 225 24 S335 104 420 72 S510 72 580 72"
                />
              </circle>
            </svg>

            <div className="trace-labels" aria-hidden="true">
              <span>Record</span>
              <span>Attest</span>
              <span>Settle</span>
            </div>
          </div>
        </div>

        <section className="shipment-card">
          <div className="card-heading">
            <div>
              <span className="section-label">Protected shipment</span>
              <h2>BND-001</h2>
            </div>

            <div className="live-chip">
              <span className="network-dot" />
              Ready
            </div>
          </div>

          <div className="route-panel">
            <span className="input-label">Route</span>
            <div>
              <strong>Nairobi</strong>
              <span className="route-arrow">→</span>
              <strong>Mombasa</strong>
            </div>
            <small>Temperature-sensitive medicine</small>
          </div>

          <div className="condition-arrow">↓</div>

          <div className="condition-panel">
            <span className="input-label">Permitted temperature</span>
            <div>
              <strong>2°C — 8°C</strong>
              <span className="condition-symbol">COLD</span>
            </div>
            <small>Settlement requires verified compliance</small>
          </div>

          <div className="bond-panel">
            <div className="bond-title">
              <span>Carrier performance bond</span>
              <strong>120 CTC</strong>
            </div>

            <div className="bond-track">
              <span style={{ width: "72%" }} />
            </div>

            <p>
              The bond returns when verified telemetry stays within the agreed
              range. A breach sends the penalty to the shipper.
            </p>
          </div>

          <button className="primary-action" type="button">
            Create protected shipment
          </button>

          <div className="transaction-notice">
            <span className="notice-orbit" aria-hidden="true" />
            <span>
              Connect a wallet to create the first attested shipment.
            </span>
          </div>
        </section>

        <aside className="condition-card">
          <div className="condition-card-header">
            <div>
              <span className="section-label">Live condition</span>
              <h2>Temperature</h2>
            </div>

            <span className="activity-mark">⌁</span>
          </div>

          <div className="temperature-visual" aria-hidden="true">
            <span className="temperature-ring ring-one" />
            <span className="temperature-ring ring-two" />
            <span className="temperature-ring ring-three" />
            <span className="temperature-core">4.2°</span>
          </div>

          <div className="metric-grid">
            <div>
              <span>Minimum</span>
              <strong>3.8°C</strong>
            </div>
            <div>
              <span>Maximum</span>
              <strong>5.1°C</strong>
            </div>
            <div>
              <span>Exposure</span>
              <strong>0 minutes</strong>
            </div>
            <div>
              <span>Status</span>
              <strong>Within bounds</strong>
            </div>
          </div>

          <div className="reserve-strip">
            <span className="lock-mark">◇</span>
            <div>
              <span>Conditional settlement</span>
              <strong>600 CTC locked</strong>
            </div>
          </div>
        </aside>
      </section>

      <section className="protocol-story">
        <div className="story-heading">
          <span className="section-label">The settlement cycle</span>
          <h2>Conditions become proof.</h2>
        </div>

        <div className="cycle-grid">
          {protocolSteps.map((step) => (
            <article key={step.number}>
              <span>{step.number}</span>
              <h3>{step.title}</h3>
              <p>{step.copy}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="evidence-section">
        <div className="evidence-heading">
          <div>
            <span className="section-label">Cross-chain evidence</span>
            <h2>One journey. Two chains. One outcome.</h2>
          </div>

          <span className="evidence-mark">◎</span>
        </div>
        <LiveSettlements />
        <div className="evidence-grid">
          <EvidenceItem label="Source chain" value="Ethereum Sepolia" />
          <EvidenceItem label="Telemetry" value="Awaiting commitment" />
          <EvidenceItem label="Proof layer" value="Attestcoin" />
          <EvidenceItem label="Settlement" value="Creditcoin" />
        </div>

        <div className="empty-evidence">
          <span className="empty-mark" aria-hidden="true" />
          <p>
            The first sensor commitment will appear here with its Sepolia
            transaction, Attestcoin proof state, and final Creditcoin
            settlement.
          </p>
        </div>
      </section>

      <footer>
        <span className="footer-brand">BOUNDS / 2026</span>
        <p>Physical conditions. Enforceable consequences.</p>
        <a href="https://docs.attestcoin.org/" rel="noreferrer" target="_blank">
          Attestcoin docs ↗
        </a>
      </footer>
    </main>
  );
}

interface EvidenceItemProps {
  label: string;
  value: string;
}

function EvidenceItem({ label, value }: EvidenceItemProps) {
  return (
    <div>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}
