# Daily Brief Skill — Research Plan

## Goal
Build a "daily brief" skill that aggregates messages, emails, calendar, and does meeting prep with web research.

---

## Phase 1: Data Source Audit

### 1.1 iMessage
- [ ] Test `imsg history` for recent messages
- [ ] Figure out how to get contact names (currently just phone numbers)
- [ ] Determine useful time window (last 24h? since last brief?)

### 1.2 WhatsApp
- [ ] Test `wacli` for message history
- [ ] Check sync status and reliability (gateway's been flapping)
- [ ] Same contact name resolution issue?

### 1.3 Gmail
- [ ] Test `gog gmail search` for recent/unread emails
- [ ] Determine what metadata is useful (sender, subject, snippet)
- [ ] Filter out noise (newsletters, notifications)

### 1.4 Google Calendar
- [ ] Already working via `gog calendar events`
- [ ] Pull today's + tomorrow's events
- [ ] Extract meeting details (attendees, descriptions, links)

---

## Phase 2: Meeting Prep Research

### 2.1 What needs research?
- Attendees (who are they? company? LinkedIn?)
- Companies mentioned in meeting titles/descriptions
- Topics mentioned that need context

### 2.2 Research tools
- [ ] Test `brave-search` for people/company lookup
- [ ] Test `summarize` for pulling context from URLs
- [ ] Consider caching to avoid re-researching known contacts

---

## Phase 3: Brief Format & Output

### 3.1 Structure options
- Plain text summary
- Markdown file (saveable, searchable)
- Spoken via TTS (`sag`)

### 3.2 Sections to include
1. **Calendar Overview** — What's on today/tomorrow
2. **Meeting Prep** — Research on attendees/topics
3. **Message Highlights** — Important convos from iMessage/WhatsApp
4. **Email Digest** — Unread/important emails
5. **Action Items** — Things that need response/attention

---

## Phase 4: Execution Model

### 4.1 Trigger options
- Morning cron (e.g., 7:30 AM)
- On-demand ("give me my brief")
- Both

### 4.2 Output destination
- Reply in current chat
- Save to `memory/briefs/YYYY-MM-DD.md`
- Both

---

## Decisions (Filled In)

1. **Time window**: Since last brief, fallback to last 24h
2. **Message filtering**: All chats initially, surface the active ones
3. **Email filtering**: Smart — skip newsletters, notifications, promos
4. **Meeting depth**: Light research — who they are, company, quick context
5. **Output preference**: Text file + voice summary via `sag`
6. **Frequency**: Both — 7:30 AM cron + on-demand

---

## Next Steps

1. Run tests on each data source (Phase 1)
2. Get Ryan's answers to open questions
3. Prototype a basic brief
4. Iterate on format and content
