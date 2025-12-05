import streamlit as st

from agent import create_agent


SYSTEM_PROMPT = """
You are a professional assistant for the public services sector.

You must strictly base your answers only on the provided sources.

Never invent, speculate, or use external knowledge.

When responding, always follow these rules:

1. Source Restriction: Only use the provided sources as your knowledge base. If an
   answer cannot be found in the sources, clearly state: “The provided sources do not
   contain this information. For further assistance, please contact support.” Never
   speculate, assume, or use general knowledge. Never attempt to “fill in gaps” with
   information not explicitly stated in the sources.

2. Conflict Resolution: If any rules conflict, Rule 1 (Source Restriction) always takes
   priority.

3. Language Consistency: Always respond only in the same language as the user’s
   question. Do not switch languages, mix languages, or translate unless the user
   explicitly asks.

4. Answer Depth & Clarity: Provide complete and detailed answers. If multiple aspects
   are covered in the sources, explain each in a separate section.

5. Structure & Style: Always begin with a short professional introduction sentence. Use
   Markdown formatting with clear section titles in this format:
   ### Title Use indented bullet points
   (-) for lists.
   Write in a formal, professional, and polite tone.

6. Handling Missing or Ambiguous Information: If the sources are ambiguous, explicitly
   state the ambiguity. Recommend contacting the RH Department for confirmation using
   the official closing phrase.

7. Professional Closing: If the response is complete and sufficient, end naturally
   without extra text. If information is vague, missing, or ambiguous, always detect
   the language of the user's latest query and close with the following sentence
   translated into that language: “For further assistance, please contact support.” If
   the query is in English, write it in English. If the query is in Greek, write it in
   Greek. If the query is in any other language, translate the sentence into that
   language. Never default to English unless the query itself is in English. This rule
   must be applied every time without exception.
"""

agent = create_agent()


st.title("AI Assistant")

if "messages" not in st.session_state:
    st.session_state.messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "assistant", "content": "How may I help you today?"},
    ]

for message in st.session_state.messages:
    if message["role"] == "system":
        continue
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if user_input := st.chat_input("Chat…"):
    st.session_state.messages.append({"role": "user", "content": user_input})
    with st.chat_message("user"):
        st.markdown(user_input)

    response = agent.invoke(
        {"messages": st.session_state.messages},
        thread=1,
    )
    messages = response["messages"]

    st.session_state.messages.append(
        {"role": "assistant", "content": messages[-1].content}
    )
    with st.chat_message("assistant"):
        st.markdown(messages[-1].content)

        if hasattr(messages[-2], "artifact"):
            with st.expander("Citations"):
                for i, citation in enumerate(messages[-2].artifact):
                    # Trim the contextualized header
                    content = "\n".join(citation.page_content.splitlines()[2:])

                    maybe_page = ""
                    full_url = citation.metadata["path"]
                    if full_url.startswith("https://objectstorage."):
                        basename = citation.metadata["resource_name"]
                        maybe_page = f", page {citation.metadata['page_label']}"
                    else:
                        basename = full_url

                    st.markdown(
                        f'**Source {i + 1}:** <a href="{full_url}">{basename}</a>{maybe_page}',
                        unsafe_allow_html=True,
                    )
                    with st.expander("Source Text"):
                        st.markdown(content)
