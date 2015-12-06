#include <stdio.h>

//DEVICE

__device__ int filtrarPixel(int* imgX, int X, int Y, int nLinhas, int nColunas,int TamFiltro)
{
	int i, j;
	int total = 0;
	int pixX, pixY;

	int a = X-(TamFiltro/2);
	int b = Y-(TamFiltro/2);

	int offset;


	for(i = 0; i<TamFiltro; i++)
	{
		for(j= 0; j<TamFiltro; j++)
		{
			pixX = a +i;
			pixY = b +j;

			if(!(pixX < 0 || pixY < 0 || pixX >= nColunas || pixY >= nLinhas))
			{
				offset = pixX*nColunas+pixY;

				total = total + imgX[offset];
			}
		}
	}
	total = total/(TamFiltro*TamFiltro);
	return(total);
}

__global__ void filtroGuassiano(int* imgX, int* imgXF, int nLinhas, int nColunas, int tamFiltro)
{
	int i = (blockIdx.x * blockDim.x) + threadIdx.x;
	int j = (blockIdx.y * blockDim.y) + threadIdx.y;

	if( i< nColunas && j< nLinhas)
	{
		//Processa!!!
		int offset = j*nColunas+i;
		imgXF[offset] = filtrarPixel(imgX, i, j, nLinhas, nColunas, tamFiltro);
		//imgXF[offset] = imgX[offset]+1;	
		//imgXF[offset] =  returnResult(imgX, offset);
	}
}


//HOST

typedef struct header
{
	char P[3];
	int x;
	int y;
	int max;
}HEADER;

typedef struct pixel{
	int R;
	int G;
	int B;
}PIXEL;

void lerPixel(int* pixR, int* pixG, int* pixB, FILE* img)
{
	fscanf(img, "%d", pixR);
	fscanf(img, "%d", pixG);
	fscanf(img, "%d", pixB);
}

void lerHeader(HEADER *head, FILE* img)
{
	char c;
	fread(head->P, sizeof(char), 2, img);
	head->P[2] = '\0';
	fseek(img, 1, SEEK_CUR);

	fread(&c, sizeof(char), 1, img);
	if(c == '#')
	{
		do{
			fread(&c, sizeof(char), 1, img);
		}while(c != '\n');
	}
	else
	fseek(img, -1, SEEK_CUR);
	fscanf(img, "%d", &head->x);
	fscanf(img, "%d", &head->y);
	fscanf(img, "%d", &head->max);

	//printf("%s\n", head->P);
	//printf("%d %d\n", head->x, head->y);

}

void lerImagem(HEADER* head, FILE* img, int** imgR, int** imgG, int** imgB)
{
	int i, j;

	for(i = 0 ; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			lerPixel(&imgR[i][j], &imgG[i][j], &imgB[i][j], img);
			//printf("%d %d %d  ", imgR[i][j], imgG[i][j], imgB[i][j]);
		}
		//printf("\n");
	}
}

void escreverImagem(int** imgR, int** imgG, int** imgB,  HEADER* head, FILE* imgSaida)
{
	int i, j;
	fseek(imgSaida, 0, SEEK_SET);

	fprintf(imgSaida, "%s\n%d %d\n%d\n", head->P, head->x, head->y, head->max);

	for(i = 0; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			fprintf(imgSaida, "%d %d %d\n", imgR[i][j], imgG[i][j], imgB[i][j]);
		}
	}
}

void escreverImagemVetor(int* imgVR, int* imgVG, int* imgVB,  HEADER* head, FILE* imgSaida)
{
	int i, j;
	int nColunas = head->x;
	int offset;

	fseek(imgSaida, 0, SEEK_SET);

	fprintf(imgSaida, "%s\n%d %d\n%d\n", head->P, head->x, head->y, head->max);

	for(i = 0; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			offset = i*nColunas+j;
			//printf("i = %d j = %d offset = %d\n", i, j, offset);
			fprintf(imgSaida, "%d %d %d\n", imgVR[offset], imgVG[offset], imgVB[offset]);
		}
	}
}

void lerImagemVetor(HEADER* head, FILE* img, int* imgVR, int* imgVG, int* imgVB)
{
	int i, j;
	int nColunas = head->x;
	int offset;

	//printf("nColunas = %d nLinhas = %d\n", head->x, head->y);

	for(i = 0 ; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{

			offset = i*nColunas+j;
			//printf("i = %d j = %d offset = %d\n", i, j, offset);
			lerPixel(&imgVR[offset], &imgVG[offset], &imgVB[offset], img);
		}
	}
}


int** alocarMatriz(int x, int y)
{
	int i;
	int **mat;

	mat = (int**) malloc (sizeof(int*)*x);
	if(mat == NULL)
	{
		printf("Erro ao alocar matriz\n");
		exit(EXIT_FAILURE);
	}

	for(i = 0; i<x;i++)
	{

		mat[i] = (int*) malloc(sizeof(int)*y);
		if(mat[i] == NULL)
		{
			printf("Erro ao alocar matriz\n");
			exit(EXIT_FAILURE);
		}
	}
	return(mat);
}

void lerImagemGray(HEADER* head, FILE* img, int** imgGray)
{
	int i, j;

	for(i = 0 ; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			fscanf(img, "%d", &imgGray[i][j]);
			//printf("%d %d %d  ", imgR[i][j], imgG[i][j], imgB[i][j]);
		}
		//printf("\n");
	}
}

void escreverImagemGray(int** imgG, HEADER* head, FILE* imgSaida)
{
	int i, j;
	fseek(imgSaida, 0, SEEK_SET);

	fprintf(imgSaida, "%s\n%d %d\n%d\n", head->P, head->x, head->y, head->max);

	for(i = 0; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			fprintf(imgSaida, "%d \n", imgG[i][j]);
		}
	}
}

void lerImagemGrayVetor(HEADER* head, FILE* img, int* imgVGray)
{
	int i, j;
	int nColunas = head->x;
	int offset;

	for(i = 0 ; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			offset = i*nColunas+j;
			fscanf(img, "%d", &imgVGray[offset]);
			//printf("%d %d %d  ", imgR[i][j], imgG[i][j], imgB[i][j]);
		}
		//printf("\n");
	}
}

void escreverImagemGrayVetor(int* imgVG, HEADER* head, FILE* imgSaida)
{
	int i, j;
	int nColunas = head->x;
	int offset;

	fseek(imgSaida, 0, SEEK_SET);

	fprintf(imgSaida, "%s\n%d %d\n%d\n", head->P, head->x, head->y, head->max);

	for(i = 0; i < head->x; i++)
	{
		for(j = 0; j < head->y; j++)
		{
			offset = i*nColunas+j;
			fprintf(imgSaida, "%d \n", imgVG[offset]);
		}
	}
}

void desalocarMatriz(int x, int **matriz)
{
	int i;
	for(i = 0; i<x; i++)
	{
    	free(matriz[i]);
	}
	free(matriz);
}

#define MAXTHREADS 4

int main( int argc, char* argv[] )
{

    int nTX, nTY;

    int n;
    int nColunas;
    int nLinhas;

    cudaError_t error;
    HEADER head;

	FILE* img;
	FILE* imgSaida;

	char *nomeImagem = NULL;
	char *extensao = NULL;
	char c = '\0';
	int i, j;
	int ext = 0;



	int* imgVR;
	int* imgVG;
	int* imgVB;

	int* imgVRF;
	int* imgVGF;
	int* imgVBF;

	int* d_imgVR;
	int* d_imgVG;
	int* d_imgVB;

	int* d_imgVRF;
	int* d_imgVGF;
	int* d_imgVBF;


	int *imgVGray;
	int *imgVGrayFinal;

	int *d_imgVGray;
	int *d_imgVGrayFinal;

	struct timespec clockStart, clockEnd;

	i = 0;
	j = 0;


	printf("Insira o caminho da imagem .ppm ou .pgm: ");
	while(c != '\n')
	{
		c = getchar();
		i++;
		nomeImagem = (char*) realloc(nomeImagem, sizeof(char)*i);
		nomeImagem[i-1] = c;

		if(c == '.')
			ext = 1;

		if(ext == 1)
		{
			j++;
			extensao = (char*) realloc(extensao, sizeof(char)*j);
			extensao[j-1] = c;
		}
	}
	nomeImagem[i-1] = '\0';
	extensao[j-1] = '\0';

	if(!strcmp(extensao, ".ppm"))
	{
		printf("Executando .PPM\n");

		img = fopen(nomeImagem, "r");
		if(img == NULL)
		{
			printf("Erro ao abrir o arquivo %s\n", nomeImagem);
			exit(EXIT_FAILURE);
		}

		lerHeader(&head, img);

		nColunas = head.x;
	    nLinhas = head.y;

	    n = nLinhas*nColunas;

	    //Calcula a quantidade de threads para cada Bloco
	    if(nColunas < MAXTHREADS)
			nTX = nColunas;
		else
			nTX = MAXTHREADS;

		if(nLinhas < MAXTHREADS)
			nTY = nLinhas;
		else
			nTY = MAXTHREADS;

		//Declara a quantidade de Threads por Bloco e o número de Blocos
		dim3 threadsPorBloco(nTX, nTY);
		dim3 numBlocos((nColunas/threadsPorBloco.x) + nColunas%threadsPorBloco.x, (nLinhas/threadsPorBloco.y)+ nLinhas%threadsPorBloco.y);


		size_t size = n*sizeof(int);



		imgVR =(int*) malloc(sizeof(int) * size);
		imgVG =(int*) malloc(sizeof(int) * size);				
		imgVB =(int*) malloc(sizeof(int) * size);

		imgVRF =(int*) malloc(sizeof(int) * size);
		imgVGF =(int*) malloc(sizeof(int) * size);				
		imgVBF =(int*) malloc(sizeof(int) * size);




		lerImagemVetor(&head, img, imgVR, imgVG, imgVB);
	
		imgSaida = fopen("out.ppm", "w");
		if(imgSaida == NULL)
		{
			printf("Erro ao criar arquivo out.ppm\n");
			exit(EXIT_FAILURE);
		}
	
		clock_gettime(CLOCK_MONOTONIC, &clockStart);

		//Uso de recursos do Dispositivo, Contagem do tempo!

		//cudaMalloc(&d_imgVR, size);
		//cudaMalloc(&d_imgVG, size);
		//cudaMalloc(&d_imgVB, size);

		//cudaMalloc(&d_imgVRF, size);
		//cudaMalloc(&d_imgVGF, size);
		//cudaMalloc(&d_imgVBF, size);

		//cudaMemcpy(d_imgVR, imgVR, size, cudaMemcpyHostToDevice);
		//cudaMemcpy(d_imgVG, imgVG, size, cudaMemcpyHostToDevice);
		//cudaMemcpy(d_imgVB, imgVB, size, cudaMemcpyHostToDevice);


		//Processa canal Red

		cudaMalloc(&d_imgVR, size);
		cudaMalloc(&d_imgVRF, size);
		cudaMemcpy(d_imgVR, imgVR, size, cudaMemcpyHostToDevice);
		
		filtroGuassiano<<<numBlocos, threadsPorBloco>>>(d_imgVR, d_imgVRF, nLinhas, nColunas, 5);
		cudaDeviceSynchronize();

		error = cudaGetLastError();
		if(error != cudaSuccess)
	    	{
	            printf("Cuda ERROR K1: %s\n", cudaGetErrorString(error));
	    	}
		
		cudaMemcpy(imgVRF, d_imgVRF, size, cudaMemcpyDeviceToHost );
		error = cudaGetLastError();
	    	if(error != cudaSuccess)
	    	{
	            printf("Cuda ERROR MemCpy1: %s\n", cudaGetErrorString(error));
	    	}

		cudaFree(d_imgVR);
		cudaFree(d_imgVRF);


		//Processa Canal Green

		cudaMalloc(&d_imgVG, size);
		cudaMalloc(&d_imgVGF, size);
		cudaMemcpy(d_imgVG, imgVG, size, cudaMemcpyHostToDevice);

		filtroGuassiano<<<numBlocos, threadsPorBloco>>>(d_imgVG, d_imgVGF, nLinhas, nColunas, 5);
		cudaDeviceSynchronize();

		error = cudaGetLastError();
		if(error != cudaSuccess)
	    	{
	            printf("Cuda ERROR K2: %s\n", cudaGetErrorString(error));
	    	
		}

		cudaMemcpy(imgVGF, d_imgVGF, size, cudaMemcpyDeviceToHost );
		error = cudaGetLastError();
	    	if(error != cudaSuccess)
	    	{
	            printf("Cuda ERROR MemCpy2: %s\n", cudaGetErrorString(error));
	    	}

		cudaFree(d_imgVG);
		cudaFree(d_imgVGF);

		
		//Processa Canal Blue

		cudaMalloc(&d_imgVB, size);
		cudaMalloc(&d_imgVBF, size);
		cudaMemcpy(d_imgVB, imgVB, size, cudaMemcpyHostToDevice);
		
		filtroGuassiano<<<numBlocos, threadsPorBloco>>>(d_imgVB, d_imgVBF, nLinhas, nColunas, 5);
		cudaDeviceSynchronize();

		error = cudaGetLastError();
	    	if(error != cudaSuccess)
	    	{
	            printf("Cuda ERROR K3: %s\n", cudaGetErrorString(error));
	    	}	

		cudaMemcpy(imgVBF, d_imgVBF, size, cudaMemcpyDeviceToHost );
	     	error = cudaGetLastError();
	    	if(error != cudaSuccess)
	    	{
	            printf("Cuda ERROR MemCpy3: %s\n", cudaGetErrorString(error));
	    	}

		cudaFree(d_imgVB);
		cudaFree(d_imgVBF);

		cudaDeviceSynchronize();

	   // cudaFree(d_imgVR); 
	    //cudaFree(d_imgVG); 
	    //cudaFree(d_imgVB); 

	    //cudaFree(d_imgVRF); 
	    //cudaFree(d_imgVGF); 
	    //cudaFree(d_imgVBF); 

	    	cudaDeviceReset();

		clock_gettime(CLOCK_MONOTONIC, &clockEnd);
		
		printf("Tempo=> %fs\n", ((double)(clockEnd.tv_nsec - clockStart.tv_nsec)/1000000000) + (clockEnd.tv_sec - clockStart.tv_sec));
	

		escreverImagemVetor(imgVR, imgVG, imgVB, &head, imgSaida);

		free(imgVR);
		free(imgVG);
		free(imgVB);


		free(imgVRF);
		free(imgVGF);
		free(imgVBF);

		fclose(imgSaida);
		fclose(img);

	}
	else if(!strcmp(extensao, ".pgm"))
	{
		printf("Executando .PGM\n");

		img = fopen(nomeImagem, "r");
		if(img == NULL)
		{
			printf("Erro ao abrir o arquivo\n");
			exit(EXIT_FAILURE);
		}
	
		lerHeader(&head, img);
	
		nColunas = head.x;
	    nLinhas = head.y;

	    n = nLinhas*nColunas;

	    //Calcula a quantidade de threads para cada Bloco
	    if(nColunas < MAXTHREADS)
			nTX = nColunas;
		else
			nTX = MAXTHREADS;

		if(nLinhas < MAXTHREADS)
			nTY = nLinhas;
		else
			nTY = MAXTHREADS;

		//Declara a quantidade de Threads por Bloco e o número de Blocos
		dim3 threadsPorBloco(nTX, nTY);
		dim3 numBlocos((nColunas/threadsPorBloco.x) + nColunas%threadsPorBloco.x, (nLinhas/threadsPorBloco.y)+ nLinhas%threadsPorBloco.y);


		size_t size = n*sizeof(int);
	
		imgVGray = (int*) malloc(sizeof(int)*size);
		imgVGrayFinal = (int*) malloc(sizeof(int)*size);
	

		lerImagemGrayVetor(&head, img, imgVGray);
	
		imgSaida = fopen("out.pgm", "w");
		if(imgSaida == NULL)
		{
			printf("Erro ao criar arquivo out.ppm\n");
			exit(EXIT_FAILURE);
		}



		clock_gettime(CLOCK_MONOTONIC, &clockStart);

		cudaMalloc(&d_imgVGray, size);
		cudaMalloc(&d_imgVGrayFinal, size);

		cudaMemcpy(d_imgVGray, imgVGray, size, cudaMemcpyHostToDevice);

		//printf("n = %d nTx = %d nTy = %d\n nBx = %d nBy = %d\n", n, threadsPorBloco.x, threadsPorBloco.y, numBlocos.x, numBlocos.y);

		filtroGuassiano<<<numBlocos, threadsPorBloco>>>(d_imgVGray, d_imgVGrayFinal, nLinhas, nColunas, 5);

		cudaDeviceSynchronize();

		error = cudaGetLastError();
	    if(error != cudaSuccess)
	    {
	            printf("Cuda ERROR 1: %s\n", cudaGetErrorString(error));
	    }

		cudaMemcpy(imgVGrayFinal, d_imgVGrayFinal, size, cudaMemcpyDeviceToHost );

		cudaDeviceSynchronize();

	    error = cudaGetLastError();
	    if(error != cudaSuccess)
	    {
	            printf("Cuda ERROR 2: %s\n", cudaGetErrorString(error));
	    }


	    cudaFree(d_imgVGray);
	    cudaFree(d_imgVGrayFinal);

	    cudaDeviceReset();

		clock_gettime(CLOCK_MONOTONIC, &clockEnd);

		printf("Tempo=> %fs\n", ((double)(clockEnd.tv_nsec - clockStart.tv_nsec)/1000000000) + (clockEnd.tv_sec - clockStart.tv_sec));

		escreverImagemGrayVetor(imgVGray, &head, imgSaida);

		free(imgVGray);
		free(imgVGrayFinal);

		fclose(imgSaida);
		fclose(img);

	}
	else
	{
		printf("Extensao nao suportada\n");
	}

    return 0;
}
