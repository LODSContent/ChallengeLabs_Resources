package com.jcs;

import java.util.IntSummaryStatistics;
import java.util.List;

public class TestMovie {

	private static MovieDAO dao = new MovieDAO();
	
	public static void main(String[] args) {

	}

//	public static void testLongMovies() {
//		List<Movie> longMovies = dao.getLongMovies();
//		for(Movie m: longMovies) {
//			System.out.println(m);
//		}
//	}
//	
//	public static void testDirector() {
//		List<Movie> directors = dao.getByDirector("Walt Disney");
//		for (Movie m : directors) {
//			System.out.println(m);
//		}
//	}
//	
//	public static void testMoviesByYear() {
//		List<String> moviesByYear = dao.getMoviesByYear("1977");
//		for(String m : moviesByYear) {
//			System.out.println(m);
//		}
//	}
//	
//	public static void testSortMoviesByDate() {
//		List<Movie> directors = dao.getByDirector("George Lucas");
//		directors = dao.sortMoviesByYear(directors);
//		for(Movie m : directors) {
//			System.out.println(m);
//		}
//	}
//	
//	public static void testDirectorStats() {
//		IntSummaryStatistics stats = dao.directorStats("John Lasseter");
//
//	}
	
}
