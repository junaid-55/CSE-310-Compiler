int check(int i){
	int f ;
	f= 12;
	if(i == 0){
		int x;
		x = 1;
		println(x);
		{
			int t;
			t=5;
		}
		return x;
	}
	else{
		int x,y;
		x = 1;
		y = 2;
		return i + x + y;
	}
	int z;
	z = 3;
	println(z);
	return z;
}

int main(){
    int i;
    i = check(0);
    println( i);
    return 0;
}
