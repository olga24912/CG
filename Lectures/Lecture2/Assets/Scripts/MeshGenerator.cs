using System;
using System.Collections.Generic;
using UnityEngine;
using Unity.Mathematics;

public class Node {
    public Vector3 pos;
    public float fvalue;
    public int active = 0;
    public int id;
    public Vector3 norm;

    public float f(Vector3 point) {
        //Debug.Log(point);
        Vector3[] centers = new[] {new Vector3((float)0.5, (float)0.7, (float)0.5), 
                                   new Vector3((float)0.7, (float)0.5, (float)0.7), 
                                   new Vector3((float)0.7, (float)0.7, (float)0.5)};
        float ans = 0;
        for (int j = 0; j < 3; ++j) {
            float res = 0;
            for (int i = 0; i < 3; ++i) {
                float cur = (float)(point[i] - centers[j][i]) * (float)(point[i] - centers[j][i]);
                res = res + cur;
            }
            ans += (float)1.0/res;
        }
        //Debug.Log(ans - 100);
        return ans - (float)50;
    }

    public Node(Vector3 pos_, int id_, float EdgeLen) {
        pos = pos_;
        fvalue = f(pos);
        if (fvalue > 0) {
            active = 1;
        }
        id = id_;
        norm = (new Vector3(f(new Vector3(pos[0] + EdgeLen, pos[1], pos[2])) - f(new Vector3(pos[0] - EdgeLen, pos[1], pos[2])), 
                                     f(new Vector3(pos[0], pos[1] + EdgeLen, pos[2])) - f(new Vector3(pos[0], pos[1] - EdgeLen, pos[2])), 
                                     f(new Vector3(pos[0], pos[1], pos[2] + EdgeLen)) - f(new Vector3(pos[0], pos[1], pos[2] - EdgeLen))));
        norm.Normalize();
    }                  
}

public class Cube {
    public List<Node> nodes = new List<Node>();
    public int Case;
    public List<Vector3> verts = new List<Vector3>();
    public List<Vector3> norms = new List<Vector3>();
    public List<int> triangles = new List<int>();

    public Cube(Node v0, Node v1, Node v2, Node v3, Node v4, Node v5, Node v6, Node v7) {
        nodes.Add(v0);
        nodes.Add(v1);
        nodes.Add(v2);
        nodes.Add(v3);
        nodes.Add(v4);
        nodes.Add(v5);
        nodes.Add(v6);
        nodes.Add(v7);
        Case = (v7.active << 7) | (v6.active << 6) | (v5.active << 5) | (v4.active << 4) | (v3.active << 3) | (v2.active << 2) | (v1.active << 1) | v0.active;
    }
    public Vector3 getVertex(Node node1, Node node2) {
        float coeff = Math.Abs(node1.fvalue)/(Math.Abs(node1.fvalue) + Math.Abs(node2.fvalue));
        return new Vector3(node1.pos[0] + coeff * (node2.pos[0] - node1.pos[0]), 
                           node1.pos[1] + coeff * (node2.pos[1] - node1.pos[1]),
                           node1.pos[2] + coeff * (node2.pos[2] - node1.pos[2]));
    }

    public Vector3 getNorms(Node node1, Node node2) {
        float coeff = Math.Abs(node1.fvalue)/(Math.Abs(node1.fvalue) + Math.Abs(node2.fvalue));
        Vector3 norm = new Vector3(node1.norm[0] + ((float)1.0 - coeff) * (node2.norm[0] - node1.norm[0]), 
                                     node1.norm[1] + ((float)1.0 - coeff) * (node2.norm[1] - node1.norm[1]),
                                     node1.norm[2] + ((float)1.0 - coeff) * (node2.norm[2] - node1.norm[2]));
        norm.Normalize();
        return norm;
    }

    public void calcTriangle() {
        int triangle_count = MarchingCubes.Tables.CaseToTrianglesCount[Case];
        List<int> first_v = new List<int> {0, 1, 2, 3, 4, 5, 6, 7, 4, 1, 2, 3};
        List<int> second_v= new List<int> {1, 2, 3, 0, 5, 6, 7, 4, 0, 5, 6, 7};
        for (int i = 0; i < triangle_count; ++i) {
            triangles.Add(verts.Count);
            triangles.Add(verts.Count + 1);
            triangles.Add(verts.Count + 2);
            int3 edges = MarchingCubes.Tables.CaseToVertices[Case][i];
            for (int j = 0; j < 3; ++j) {
                verts.Add(getVertex(nodes[first_v[edges[j]]], nodes[second_v[edges[j]]]));
                norms.Add(getNorms(nodes[first_v[edges[j]]], nodes[second_v[edges[j]]]));
            }
        }        
    }

}

public class CubeGrid {
    public Cube[,,] cubes;
    public Node[,,] nodes;
    public int xlen, ylen, zlen;
    public float edgeLen;

    public List<int> sourceTriangles = new List<int>(); 
    public List<Vector3> sourceVertices = new List<Vector3>(); 
   
    public CubeGrid(float lenSize) {
        edgeLen = lenSize;
        xlen = (int)Math.Round(1.0/lenSize) + 1;
        ylen = (int)Math.Round(1.0/lenSize) + 1;
        zlen = (int)Math.Round(1.0/lenSize) + 1;   
    }

    public void genNode() {
        nodes = new Node[xlen,ylen,zlen];
        int cur_id = 0;
        for (int i = 0; i < xlen; ++i) {
            for (int j = 0; j < ylen; ++j) {
                for (int g = 0; g < zlen; ++g) {
                    Vector3 pos = new Vector3(i * edgeLen, j * edgeLen, g * edgeLen);
                    nodes[i,j,g] = new Node(pos, cur_id, edgeLen);
                    cur_id += 1;                         
                } 
            }
        }
    }

    public void genCube() {
        cubes = new Cube[xlen - 1, ylen - 1, zlen - 1];
        for (int i = 0; i < xlen - 1; ++i) {
            for (int j = 0; j < ylen - 1; ++j) {
                for (int g = 0; g < zlen - 1; ++g) {
                    cubes[i, j, g] = new Cube(nodes[i, j, g], nodes[i, j + 1, g], nodes[i + 1, j + 1, g], 
                                              nodes[i + 1, j, g], nodes[i, j, g + 1], nodes[i, j + 1, g + 1], 
                                              nodes[i + 1, j + 1, g + 1], nodes[i + 1, j, g + 1]); 
                    cubes[i, j, g].calcTriangle();
                    List<int> list_tmp_triangle = cubes[i, j, g].triangles;
                    List<Vector3> list_tmp_points = cubes[i, j, g].verts;
                    int cur_num = sourceVertices.Count;
                    for (int h = 0; h < list_tmp_points.Count; ++h) {
                        sourceVertices.Add(list_tmp_points[h]);
                    }
                    for (int h = 0; h < list_tmp_triangle.Count; ++h) {
                        sourceTriangles.Add(list_tmp_triangle[h] + cur_num);
                    }
                }
            }
        }
    }

    public void genTriangle() {
        genNode();
        genCube();
    }
}

[RequireComponent(typeof(MeshFilter))]
public class MeshGenerator : MonoBehaviour
{
    private MeshFilter _filter;
    private Mesh _mesh;

    /// <summary>
    /// Executed by Unity upon object initialization. <see cref="https://docs.unity3d.com/Manual/ExecutionOrder.html"/>
    /// </summary>
    private void Awake()
    {
        _filter = GetComponent<MeshFilter>();
        _mesh = _filter.mesh = new Mesh();
        _mesh.MarkDynamic();
    }

    /// <summary>
    /// Executed by Unity on every first frame <see cref="https://docs.unity3d.com/Manual/ExecutionOrder.html"/>
    /// </summary>
    private void Update()
    {
        CubeGrid cubegrid = new CubeGrid((float)0.05);
        cubegrid.genTriangle();
        
        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> norms = new List<Vector3>();
        List<int> triangles = new List<int>();

        // What is going to happen if we don't split the vertices? Check it out by yourself by passing
        // sourceVertices and sourceTriangles to the mesh.
        for (int i = 0; i < cubegrid.sourceTriangles.Count; i++)
        {
            triangles.Add(vertices.Count);
            Vector3 vertexPos = cubegrid.sourceVertices[cubegrid.sourceTriangles[i]];
            Vector3 vnorm = cubegrid.sourceVertices[cubegrid.sourceTriangles[i]];
           
            //Uncomment for some animation:
            //vertexPos += new Vector3
            //(
            //    Mathf.Sin(Time.time + vertexPos.z),
            //    Mathf.Sin(Time.time + vertexPos.y),
            //    Mathf.Sin(Time.time + vertexPos.x)
            //);
            
            vertices.Add(2*(vertexPos - new Vector3((float)0.5, (float)0.5, (float)0.5)));
            norms.Add(vnorm);
        }

        // Here unity automatically assumes that vertices are points and hence will be represented as (x, y, z, 1) in homogenous coordinates
        _mesh.SetVertices(vertices);
        _mesh.SetTriangles(triangles, 0);
        _mesh.SetNormals(norms);
        //_mesh.RecalculateNormals();

        // Upload mesh data to the GPU
        _mesh.UploadMeshData(false);
    }
}