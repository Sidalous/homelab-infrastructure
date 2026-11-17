# ADR-01: Monitoring and Alerting Function

| Field            | Value                                              |
| ---------------- | -------------------------------------------------- |
| **ADR ID**       | ADR-01                                             |
| **Date**         | 25-09-2026                                         |
| **Status**       | Proposed                                           |
| **Deciders**     | Connor Baird                                       |
| **Related**      | N/A                                                |

---

## Context

I want to implement monitoring, alerting and a metrics dashboard in my homelab. Currently I do not have any of these in place, meaning any errors, misconfigurations, bottlenecks and resource overuse go unnoticed until it is too late - this can increase the risk of data loss or corruption, as well as excessive wear on hardware components. Currently my homelab is fairly low in resource usage, but with additional VMs and resource allocation, now is a good time to get hard metrics in one place for analysis. This will help me identify any hardware shortcomings, and decide if any components need upgrading. I am particularly concerned with RAM usage, as OOM killer targeting plex services with I/O has the potential to cause serious issues. With the price of RAM and other computer hardware at a considerable premium to just a few years ago, this analysis is key to keeping the homelab functioning as required, whilst keeping expenses low.  

I need to choose an industry standard package, that is widely used but also fulfilling the requirements of my homelab's needs. Ideally it needs to be lightweight, relatively user-friendly, industry standard and able to allow the creation of custom dashboards, indicating key system metrics. These metrics and dashboard will be featured on my portfolio site, in a NOC-style set up. 

## Decision

**Metrics Layer**
When it comes to the metrics and data layer, Prometheus is most commonly listed in job listing for my target junior roles. It also has a wide ecosystem of tools that can be utilised, especially when it comes to exporters. This means I am wiring and plugging things together, not writing custom integrations. This will help with modularity, maintenance and ease of use. 

Prometheus uses a pull-based model, meaning it pulls/scrapes data from the targets individually, rather than the targets pushing the data to a central server. This means the adding of VMs/devices will not require a re-configure, only an updated target list. 

**Visualisation & Dashboarding Layer**
Grafana pairs perfectly with Prometheus. They are often quoted as a pair in job descriptions. Grafana provides visualisation and dashboarding facilities for the data pulled by Prometheus. Whilst Grafana is data source agnostic, the Prometheus/Grafana stack is incredibly popular because of the pull based model, RHEL nativity, and the lack of heavy dependencies. 

## Alternatives Considered

**Prometheus Alternatives**
Zabbix - rejected due to learning curve, database backend and PHP frontend. UI can feel dated.
Telegraf - Tied in with InfluxDB and related ecosystem. It is also a push-based model. 
Datadog - SaaS model, with no option to self-host. Not suitable for this set up.
**Grafana Alternatives**
Kibana - designed to work closely with Elastisearch. Recent licencing changes may affect access. Often seen in job listings. 
SigNoz - newer, less community and advanced features when compared to Grafana


## Consequences

**Positives**
- once operational, I will have full monitoring set up with a custom dashboard, allowing in depth analysis
- I will have learnt how to initialise, set up and refine Prometheus and Grafana - an important workflow for my future role
- I will have learned at least some PromQL (Prometheus Query Language) - this is also used in various other tools 
- I will have a dashboard I can integrate into my portfolio site
**Negatives**
- I will have more packages and integrations to maintain and manage 
- additional load from the monitoring VM - see point above regarding resource allocation
- Prometheus local storage isn't replicated. if the VM dies, the history is lost 

### Risks / Unknowns
- unknown: how hard or time intensive will this be?
- assumption: there will be plenty of official & community documentation to help guide me 
- risks: information overload with too many metrics being captured - fine tuning and dashboard refining will be needed

