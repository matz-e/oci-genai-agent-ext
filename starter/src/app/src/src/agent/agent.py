import functools
import httpx
import oci
import oracledb
import os

from dotenv import load_dotenv

from langchain.agents import create_agent as create_langchain_agent
from langchain.tools import tool

from langchain_openai import ChatOpenAI

from oci_openai import OciInstancePrincipalAuth
from langchain_oci import OCIGenAIEmbeddings

from langchain_community.vectorstores.oraclevs import OracleVS
from langchain_community.vectorstores.utils import DistanceStrategy

load_dotenv()


@functools.cache
def get_vectorstore() -> OracleVS:
    connection = oracledb.connect(
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        dsn=os.getenv("DB_URL"),
    )
    connection.autocommit = True

    region = os.getenv("EMBEDDING_REGION", "me-riyadh-1")
    model = os.getenv("EMBEDDING_MODEL", "cohere.embed-v4.0")
    endpoint = f"https://inference.generativeai.{region}.oci.oraclecloud.com"

    embeddings = OCIGenAIEmbeddings(
        model_id=model,
        service_endpoint=endpoint,
        compartment_id=os.environ["COMPARTMENT_ID"],
        auth_type="INSTANCE_PRINCIPAL",
    )

    return OracleVS(
        client=connection,
        table_name="docs_langchain",
        embedding_function=embeddings,
        distance_strategy=DistanceStrategy.DOT_PRODUCT,
    )


def create_agent():
    region = os.getenv("GENERATION_REGION", "eu-frankfurt-1")
    model = os.getenv("GENERATION_MODEL", "openai.gpt-oss-120b")
    endpoint = f"https://inference.generativeai.{region}.oci.oraclecloud.com"

    model = ChatOpenAI(
        model=model,
        api_key="OCI",
        base_url=f"{endpoint}/20231130/actions/v1",
        http_client=httpx.Client(
            auth=OciInstancePrincipalAuth(),
            headers={"CompartmentId": os.environ["COMPARTMENT_ID"]},
        ),
    )

    @tool(response_format="content_and_artifact")
    def retrieve_docs(query: str):
        """Search the knowledge base for supporting documents, with the highest score returned first"""
        result = get_vectorstore().similarity_search_with_score(query, k=5)
        retrieved_docs, scores = zip(*result)
        for doc, score in zip(retrieved_docs, scores):
            doc.metadata["score"] = score
        serialized = "\n\n".join(
            f"Source: {doc.metadata['path']}\nScore: {doc.metadata['score']}\nContent: {
                doc.page_content
            }"
            for doc in retrieved_docs
        )
        return serialized, retrieved_docs

    tools = [retrieve_docs]
    return create_langchain_agent(model, tools)


if __name__ == "__main__":
    response = create_agent().invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": "Ποιος είναι ο αρμόδιος λειτουργός αγοράς όταν η εκτιμώμενη αξία είναι 400",
                }
            ]
        }
    )
    print(response["messages"][-1].content)

# def to_citations(tool_call):
#     print(dir(tool_call))
#     if tool_call.type != "tool":
#         return
#     for artifact in tool_call.artifact:
#         if artifact.type != "Document":
#             continue
#         yield {
#             "doc-id": artifact.metadata["doc_id"],
#             "metadata": None,
#             "page-numbers": artifact.metadata["page_label"],
#             "source-location": {
#                 "function-name": "",
#                 "id": artifact.metadata["doc_id"],
#                 "source-location-type": "OCI_DATABASE",
#                 "url": artifact.metadata["path"],
#             },
#             "source-text": artifact.page_content,
#             "title": "",
#         }
#         return
#

# app = FastAPI()
#
# class Interaction(BaseModel):
#     userMessage: str
#     sessionId: str
#     shouldStream: bool
#
# @app.post("/sessions")
# def get_session(data: dict):
#     return {"id": "tu_es_numero_uno"}
#
#
#
#
# @app.post("/actions/chat")
# def chat(interaction: Interaction):
#     response = agent.invoke(
#         {"messages": [{"role": "user", "content": interaction.userMessage}]},
#         thread=interaction.sessionId,
#     )
#     messages = response["messages"]
#     if len(messages) > 1:
#         tool_call = messages[-2]
#         citations = to_citations(tool_call)
#     text = messages[-1].content
#
#     return {
#         "data": {
#             "message": {
#                 "role": "AGENT",
#                 "content": {
#                     "citations": citations,
#                     "paragraph-citations": None,
#                     "text": text,
#                 },
#                 "time-created": "1970-01-01T00:00:00.000000+00:00",
#             }
#         }
#     }
