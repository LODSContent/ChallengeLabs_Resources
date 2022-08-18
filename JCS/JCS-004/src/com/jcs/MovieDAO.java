package com.jcs;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class MovieDAO {
	private List<Movie> movieList;
	
	public MovieDAO(List<Movie> movies) {
		movieList = movies;
	}
	
	public List<Movie> orderBy(List<Movie> m, Comparator<Movie> c){
		Collections.sort(m, c);
		return m;
	}
	
}
