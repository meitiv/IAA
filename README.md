# IAA
Smart contract for tracking Inter Agency Agreements

The Ethereum contract is a repository of Inter Agency Agreements.
Each Agreement is identified by a unique ID and the parties:
Requesting Agency (RA) and the Servicing Agency (SA).  Both are
identified by their respective Ethereum addresses.  The agreement
contains the RA and SA identities, start date, list of deliverables,
and two boolean variables that reflect the approval status by the
respective agencies.  Each deliverable has a description, due date,
payment amount, and a boolean state variable reflecting whether its
been delivered.